# Clean Architecture

When to load this reference: when structuring a new service or module, drawing boundaries between components, deciding what a microservice should own, untangling framework coupling, reviewing a system for testability and longevity, or choosing a top-level folder structure.

Clean Architecture is Uncle Bob's synthesis of Hexagonal Architecture (Alistair Cockburn), Onion Architecture (Jeffrey Palermo), DCI (Coplien & Reenskaug), and BCE (Ivar Jacobson, *Object-Oriented Software Engineering*, 1992). They differ in detail but agree on one goal: **separation of concerns by layering**, with business rules isolated from delivery mechanisms.

The foundational insight comes from Jacobson: **architectures are structures that support the use cases of the system.** Not frameworks. Not databases. Not UIs. Use cases.

---

## What a Clean Architecture Produces

A system that is:

1. **Independent of frameworks.** Frameworks are tools, not constraints.
2. **Testable.** Business rules tested without UI, DB, web server, or any external element.
3. **Independent of UI.** The UI can be replaced (web → console → CLI → TUI) without touching business rules.
4. **Independent of database.** Swap PostgreSQL for MongoDB, ClickHouse, or in-memory without rewriting domain logic.
5. **Independent of any external agency.** The core business rules know nothing about the outside world.

**The database is a detail.** So is the web. So is the framework. These are the most common sources of architectural rot because developers mistake them for foundations.

> "The database is merely an IO device. It happens to provide some useful tools for sorting, querying, and reporting but those are ancillary to the system architecture." — *A Little Architecture* (2016)

---

## The Dependency Rule

The one rule that makes everything else work:

> **Source code dependencies point only inward, toward higher-level policy.**

- Nothing in an inner layer may name anything from an outer layer — no function, class, variable, or data format.
- Data formats convenient for the outer layer (ORM row struct, JSON DTO) must not leak inward.
- Control flow may cross boundaries in either direction, but *source dependencies* point only inward. The Dependency Inversion Principle (see [solid.md](solid.md)) is the mechanism that makes this possible when control flow runs outward.

When this rule is obeyed, external details — databases, frameworks, UIs — become replaceable plugins.

---

## The Four Concentric Layers

Schematic. You may need more or fewer for a given system, but the Dependency Rule always applies.

### 1. Entities (innermost)

Encapsulate **enterprise-wide** business rules. An entity can be a class with methods or a data structure plus functions — style choice.

- Entities know nothing about applications, use cases, frameworks, or anything outside.
- For single applications (no "enterprise"), these are your core business objects.
- These are the least affected by operational change. Changes to page navigation, auth mechanisms, or DB schemas must not reach here.

### 2. Use Cases

Encapsulate **application-specific** business rules. Use cases orchestrate entities to accomplish the application's goals.

- A use case directs entities; it does not contain enterprise-wide rules itself.
- Changes to the application's *behavior* land here. Changes to externalities do not.
- Simple request/response data structures (not entities) flow in and out.

### 3. Interface Adapters

Convert data between the format convenient for use cases/entities and the format convenient for external agencies.

- MVC's Controllers, Presenters, and Views live here.
- All SQL lives here (if the database is SQL). Nothing inside knows about SQL.
- DTOs are translated into domain types and back here.

### 4. Frameworks and Drivers (outermost)

The web framework, the database, the message broker, the file system. Glue code only — you do not write much application logic here. Details live here because details change, and the outer ring is where change is cheap.

---

## Crossing Boundaries

When control flow needs to run outward — a use case needs to call a presenter — a direct call violates the Dependency Rule (the inner layer names something in the outer layer).

**Solution: the Dependency Inversion Principle.** The use case calls an interface (an "output port") defined in its own layer. The outer-layer presenter implements that interface. Control flows outward; source dependencies point inward. Same pattern works for repositories, gateways, any outward call.

---

## What Crosses Boundaries

Only **simple data structures** cross boundaries:
- Plain structs or Data Transfer Objects.
- Primitive arguments in function calls.
- Maps/dictionaries, when appropriate.

Never pass Entity objects or ORM row objects across boundaries — that couples layers. Translate to the format most convenient for the inner circle at every boundary crossing.

---

## Screaming Architecture

From the 2011 blog post of the same name. The top-level layout of a project should *scream* what the system does, not what framework it uses.

**The blueprint metaphor.** Imagine looking at the blueprints of a building. A single-family residence: front entrance, foyer, living room, dining room, kitchen. A library: grand entrance, check-in clerks, reading areas, galleries of bookshelves. A shopping mall: corridors, store bays, parking lots. You can tell what kind of building it is before you see any sign.

What does *your* application architecture scream?

**Bad top-level:** `controllers/`, `models/`, `views/`, `services/`. Tells you the system uses MVC. Tells you nothing about what the system is for.

**Good top-level:** `billing/`, `shipping/`, `catalog/`, `fraud_detection/`. Now you know what the system does.

**Why it matters:** A good architecture lets you defer decisions about Rails, Spring, Hibernate, Tomcat, MySQL, or React until much later in the project. A framework-centric top-level locks those decisions in day one, and also makes the code base mute about its own purpose. The web is a *delivery mechanism*; the database is a *detail*. Neither should dominate your system structure.

If a stranger cannot tell from the directory structure whether they are looking at an e-commerce platform or a hospital records system, the architecture is failing at the highest level.

---

## Component Principles

Once modules are organized, they group into **components** — independently deployable units (libraries, services, jars, crates). Two sets of principles govern them.

### Component Cohesion

- **REP — Reuse/Release Equivalence Principle.** The unit of reuse is the unit of release.
- **CCP — Common Closure Principle.** Group together classes that change for the same reasons at the same times. (SRP at component scale.)
- **CRP — Common Reuse Principle.** Classes used together belong together; classes not used together don't. (ISP at component scale.)

These three pull in different directions — the **tension diagram** is a triangle and component design is an ongoing balance. Early-stage projects lean toward REP+CCP (ship quickly, include more); mature, widely-reused components shift toward CRP (exclude what clients don't need).

### Component Coupling

- **ADP — Acyclic Dependencies Principle.** The dependency graph among components must have no cycles. Break cycles with DIP or by extracting a new component both sides depend on.
- **SDP — Stable Dependencies Principle.** Depend in the direction of stability.
- **SAP — Stable Abstractions Principle.** Stable components should be abstract; volatile components should be concrete.

---

## Applying This in Practice

- **"NO DB" and "NO Web" are valid starting positions.** Business rules should be expressible, testable, and useful before either is chosen.
- **Frameworks are tools, not partners.** Wrap them. Keep `import django` or `import axum::Router` out of the core. (Uncle Bob's 2014 "Framework Bound" is a full rant on this.)
- **Not every project needs four full circles.** Small projects may collapse Entities and Use Cases into one layer. The Dependency Rule still applies whatever the count.
- **The seams matter most.** Architecture lives at the boundaries between components. Defend them at every review — once they rot, replacing a dependency stops being a weekend task and becomes a six-month project.
- **Dialog from *A Little Architecture* (2016).** An aspiring architect says they want to make decisions about databases, frameworks, and webservers. Uncle Bob's response: "Oh. Well, then you don't want to become a Software Architect after all." The architect's job is to make decisions that let you **defer** the irrelevant decisions.

---

## Architecture and Agility

From "The Scatology of Agile Architecture" (2009): Agile does *not* mean no up-front architecture. The myth that you evolve architecture from zero is, in Uncle Bob's words, "horse shit." Good teams do enough architecture up front to get the seams right, then let the details emerge inside those seams. See [craft.md](craft.md) for more on this.
