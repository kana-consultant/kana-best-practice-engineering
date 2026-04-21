# SOLID Principles

The five class- and module-level principles that make a codebase flexible, testable, and resistant to rot. Load when designing a new class, module, or microservice; when refactoring for flexibility; or when reviewing dependencies between units.

Uncle Bob reaffirmed in 2020 that these principles remain as relevant as they were in the 1990s, and that microservices and dynamic typing do *not* make them obsolete. The shape of software — sequence, selection, iteration — has not fundamentally changed since the first stored-program computer, and neither has the shape of good design.

The "SOLID" acronym was popularized by Uncle Bob, but most of the individual principles predate him. Understanding the roots helps you reason about them when they seem to conflict.

---

## SRP — Single Responsibility Principle

**Roots.** David L. Parnas, "On the Criteria To Be Used in Decomposing Systems into Modules" (CACM 15:12, December 1972): "begin decomposition with a list of difficult design decisions or design decisions *which are likely to change*. Each module is designed to hide such a decision from the others." Edsger Dijkstra's 1974 paper "On the role of scientific thought" coined **Separation of Concerns**. Larry Constantine, Tom DeMarco, and Meilir Page-Jones formalized **cohesion** as "functional relatedness" through the 1970s and 1980s. Uncle Bob consolidated these into "SRP" in the late 1990s (he suspects he borrowed the name from Bertrand Meyer).

**The definition has evolved three times:**

1. *Early:* "A module should do one thing, do it well, and do it only."
2. *Clean Code era (2008):* "A class should have one, and only one, reason to change."
3. *Clean Architecture (2017):* "A module should be responsible to one, and only one, **actor**." An actor is a person or a tightly coupled group representing a single narrowly defined business function.

The actor formulation is the current canonical one. Uncle Bob gave this example (2014): "SRP is about people. When you write a software module, you want to make sure that when changes are requested, those changes can only originate from a single person, or rather, a single tightly coupled group of people representing a single narrowly defined business function. Why? Because we don't want to get the COO fired because we made a change requested by the CTO."

**What this means in practice:**
- Business rules do not live in GUI code.
- SQL queries do not live next to communication protocols.
- A module modified because of a change in report format should not also be modified because of a change in tax law — those are different actors.
- Microservices do not solve SRP. A tangled microservice is still tangled; a tangled set of microservices is worse than a tangled monolith because the tangles cross network boundaries.

**Smells that suggest SRP violation:**
- The class keeps getting edited by different people for different reasons.
- Changing one feature breaks tests for an unrelated feature.
- The class name contains "and," "manager," "util," or "helper."

---

## OCP — Open-Closed Principle

**Roots.** Bertrand Meyer, *Object-Oriented Software Construction* (1988). Meyer's original formulation used **implementation inheritance**: "A class is closed, since it may be compiled, stored in a library, baselined, and used by client classes. But it is also open, since any new class may use it as parent, adding new features."

In the 1990s the principle was **reinterpreted polymorphically** (largely by Uncle Bob's writing): use abstracted interfaces with multiple implementations, not base-class inheritance. This is the dominant modern reading.

**Definition (modern):** "A module should be open for extension but closed for modification." Or: "You should be able to extend the behavior of a system without having to modify that system."

**In practice:**
- Imagine writing a system where writing to disk, printer, screen, or network pipe were scattered as `if` cases throughout business logic. That is the OCP failure mode — and why operating systems invented device independence.
- New payment methods plug in without modifying the checkout flow. New report formats plug in without modifying the report generator.
- **Plugin architectures are the apotheosis of OCP.** Eclipse, IntelliJ, VS Code, Vim, Minecraft — all extend without modifying.

**Simple code is both open and closed.** Complexity in this dimension comes from *missing* abstractions, not extra ones. Do not over-abstract speculatively.

---

## LSP — Liskov Substitution Principle

**Roots.** Barbara Liskov's 1987 keynote "Data abstraction and hierarchy" at OOPSLA, later formalized with Jeannette Wing (1994). Liskov's own framing is mathematical: about subtypes that preserve the behavior their supertype's clients expect.

**A common misread:** LSP is about inheritance. It is not — it is about **subtyping**. Subtyping includes:
- Interface implementations.
- Trait/protocol implementations.
- Duck types that satisfy an implicit interface.
- Any context where "type B can be used where type A is expected."

**Canonical definition (Uncle Bob):** "A program that uses an interface must not be confused by an implementation of that interface."

**In practice:**
- The classic Square-from-Rectangle example: Square cannot be substituted for Rectangle without surprising callers who expect to vary width and height independently.
- Keep subtype contracts crisp. Document invariants, preconditions, postconditions (Meyer's Design by Contract from *OOSC*).
- If a subtype needs to refuse operations the base type promised, the hierarchy is wrong.
- An abstraction that leaks its concretions breaks LSP.

Michael Feathers noted (2006) that in dynamic languages LSP applies just as strongly — it is about substitutability, not inheritance. Duck typing gives you substitutability; LSP is what ensures substituted objects behave sensibly.

---

## ISP — Interface Segregation Principle

**Definition:** "Keep interfaces small so that clients don't end up depending on things they don't need."

ISP matters most where compile-time or link-time coupling exists — which is still most of the industry. In statically typed languages (Rust, Java, Go, C#, C++, Swift, TypeScript with strict mode), when module A depends on module B at compile time but only uses one method, a change to an unrelated method in B still triggers recompilation and redeployment of A.

Dynamically typed languages are not immune — package managers (npm, Maven, Cargo, pip) impose coupling through version resolution.

**In practice:**
- Prefer many small, role-focused interfaces over one fat interface.
- Split a class with two unrelated interfaces into two classes (often aligns with SRP).
- In Rust, favor small focused traits over giant trait blobs.

---

## DIP — Dependency Inversion Principle

**Definition:** "Depend in the direction of abstraction. High-level modules should not depend on low-level details; both should depend on abstractions."

This is the single most important architectural principle. Computations that produce business value must not depend on:
- SQL dialects.
- HTTP framework types.
- File formats.
- UI widget libraries.
- Vendor SDKs.

**The mechanic (from "OO vs FP", 2014):** In most software systems when one function calls another, the runtime dependency and the source-code dependency point the same direction. When polymorphism is injected between them, an **inversion of the source-code dependency** occurs. The calling module still depends on the called module at runtime, but the source of the calling module depends only on a polymorphic interface — not on the source of the called module. The called module becomes a plugin.

**In practice:**
- Define interfaces in terms of what the domain needs, not what the infrastructure provides.
- Place those interfaces in the high-level module; place implementations in the low-level module.
- Wire them together in a single composition root (the Main component).
- "To be robust, a system must employ polymorphism across significant architectural boundaries."

DIP is the mechanism that makes Clean Architecture's Dependency Rule enforceable. See [architecture.md](architecture.md).

---

## Component Principles

Once modules are organized, they group into **components** — independently deployable units (libraries, services, jars, crates). Two sets of principles govern them.

### Component Cohesion — what belongs together

- **REP — Reuse/Release Equivalence Principle.** The unit of reuse is the unit of release. Things reused together must be released together, with version numbers.
- **CCP — Common Closure Principle.** Group together classes that change for the same reasons at the same times. (SRP at component scale.)
- **CRP — Common Reuse Principle.** Classes that are used together belong together; classes that are not used together do not belong together. (ISP at component scale.)

**The tension diagram.** These three principles pull in different directions — REP and CCP tend to include more; CRP tends to exclude. Designing components is an ongoing balance within the triangle they form. Where you place a component in this triangle depends on maturity: early-stage components lean toward REP+CCP (include-more); mature, widely-reused components shift toward CRP (exclude).

### Component Coupling — how they relate

- **ADP — Acyclic Dependencies Principle.** The dependency graph among components must have no cycles. Break cycles with DIP or by extracting a new component both sides depend on.
- **SDP — Stable Dependencies Principle.** Depend in the direction of stability. Volatile components may depend on stable ones, never the reverse.
- **SAP — Stable Abstractions Principle.** Stable components should be abstract, so they can be extended. Volatile components should be concrete. Corollary: depend on stable abstractions.

---

## Applying SOLID in Practice

- **Do not apply all five at once on day one.** Let the code tell you which principle is being violated. Pain surfaces one at a time.
- **Duplication and rigidity are the strongest signals.** If you cannot change one thing without changing ten, some SOLID principle is being violated — usually SRP or DIP.
- **Beware of over-abstraction.** SOLID is about *managing* dependencies, not maximizing interfaces. A speculative interface with one implementation is YAGNI until a second implementation appears or tests demand it.
- **Uncle Bob's synthesis (2020):** Simple code is both open and closed. Simple code maintains crisp subtype relationships. Simple code depends on abstractions. The principles describe what simple code looks like when it survives contact with change.
