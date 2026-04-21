# Programming Paradigms

When to load this reference: when choosing between procedural and OO style, writing code in a functional language, refactoring switch statements, handling persistence, or when the user asks about OO vs FP, design patterns, or Clean Code's chapter on objects and data structures.

Uncle Bob's reductionist framing of the three paradigms is a powerful lens for reasoning about code shape. Each paradigm imposes **discipline** by **taking something away** from the programmer.

---

## The Three Paradigms

Each paradigm is defined by what it *forbids*, not by what it enables. This is Dijkstra-style reasoning: fewer primitives mean fewer ways to be wrong.

### Structured Programming

- **Forbids:** `goto` (direct transfer of control).
- **Provides:** Sequence, Selection (if/else), Iteration (while). Dijkstra proved any algorithm can be expressed with just these three.
- **Why:** Dijkstra's 1968 letter "Go To Statement Considered Harmful." Unrestricted `goto` makes programs impossible to reason about. Restricted control flow is provably correct for sequence, selection, iteration; not provably correct with arbitrary `goto`.
- **Status today:** Won so completely that most developers don't even realize they're using it. Modern languages don't have `goto` (or discourage it).

### Object-Oriented Programming

- **Forbids:** Raw function pointers / indirect transfer of control through unmanaged pointers.
- **Provides:** Polymorphism. The language manages the function pointers for you.
- **Why:** Raw function pointers (as in C) are correct but fragile — every caller must follow conventions every time. Polymorphism provides the same runtime capability through a disciplined mechanism: objects carry their own dispatch table, set up once when the object is created.
- **The reductionist core:** OO = polymorphism. Encapsulation, methods-bound-to-data, and simple inheritance exist in C and Pascal too. **What OO uniquely gives you is convenient polymorphism.** "OO without polymorphism is not OO."

### Functional Programming

- **Forbids:** Assignment / mutation of state.
- **Provides:** Referential transparency. Same inputs → same outputs, always, everywhere.
- **Why:** Shared mutable state is the source of most concurrency bugs and most "action at a distance" reasoning failures. Forbidding it means state changes are explicit and localized.
- **The reductionist core:** FP = referential transparency. Higher-order functions exist in OO languages too (Smalltalk, etc.). What FP uniquely gives you is the guarantee that a function call cannot change anything you didn't pass to it.

### Why "Three Paradigms" Matters

These are **orthogonal**, not competing. Each removes a different freedom:

| Paradigm | Discipline on | Mechanism |
|---|---|---|
| Structured | Direct transfer of control | No `goto` |
| OO | Indirect transfer of control | Polymorphism |
| FP | Assignment | Referential transparency |

A language can (and modern ones often do) impose all three disciplines at once. You can write OO code functionally, and you can apply SOLID inside a functional program.

---

## OO and FP Are Orthogonal, Not Exclusive

From Uncle Bob's 2014 and 2018 "FP vs OO" posts:

> "The principles of software design still apply, regardless of your programming style. The fact that you've decided to use a language that doesn't have an assignment operator does not mean that you can ignore the Single Responsibility Principle; or that the Open Closed Principle is somehow automatic."

And from his 2023 *Functional Classes* post: "Should you subdivide a functional program into classes the way you would an object oriented program? Yes. You should. Because the rules don't change just because you've chosen to use immutable data structures."

**A class, reductively:** "A group of cohesive and narrowly defined functions that operate on an encapsulated data structure. The functions may, or may not, be polymorphically deployed." This definition works in Clojure, Haskell, Rust, Java, TypeScript, Python.

**The design principles transcend paradigm:**
- SRP applies in Clojure (group functions by actor).
- OCP applies in Haskell (use abstraction, add type class instances).
- DIP applies anywhere there are modules.
- A "class" in the sense above is a cohesive namespace of related functions plus the data they operate on.

---

## Data/Object Anti-Symmetry

From Chapter 6 of *Clean Code* and elaborated in the 2019 blog post "Classes vs. Data Structures."

**Two definitions that complement each other:**

- **Object:** A set of functions that operate on **implied** data. Data exists but is hidden. Callers see only functions.
- **Data structure:** A set of data elements operated on by **implied** functions. Data is exposed. Functions exist but are not specified by the structure.

They are **diametric opposites**. You cannot fully be both.

### Consequences

- **DTOs are data structures, not objects.**
- **Database tables are data structures, not objects.**
- **"ORM" is a misnomer.** There is no mapping between database tables and objects. ORMs map tables to data structures. (This is not pedantic; it explains why ORMs have the smells they do.)
- **Polymorphism is the marker of objects.** When `shape.area()` dispatches dynamically to the Circle or Square implementation, you are doing OO. When `area(shape)` is a free function with `match shape { Circle => …, Square => … }`, you are doing procedural work.

### The Four Symmetry Rules

These tell you when to choose each style.

| | Add new FUNCTION | Add new TYPE |
|---|---|---|
| **Classes (OO)** | **Hard** — change every class | **Easy** — add one class |
| **Data structures (procedural)** | **Easy** — add one function | **Hard** — change every function |

**Choose by expected axis of change:**

- If you expect more new functions than new types → procedural style with data structures + functions (e.g., visitor pattern, pattern matching over enums, Clojure-style).
- If you expect more new types than new functions → OO style with classes and polymorphism.
- The **Visitor pattern** is procedural-style behavior over OO data — it bridges the two.

**In Rust specifically:** enums with `match` are procedural by this taxonomy (add a variant → every match must handle it); traits with implementations are OO (add an impl → no existing code changes). Neither is wrong; choose by axis of change. If new variants are rare and new operations are common, the enum wins. If new types are common, the trait wins.

---

## Polymorphism and if-else-switch

From "if-else-switch" (2021). A very common refactor:

**The pattern.** When you see an if/else chain or switch that branches by type or by "kind," replace it with:

1. A base class or interface with one method per case.
2. Concrete implementations, one per branch.
3. A **factory** that creates the right implementation based on the discriminator (this is where the if/else/switch ends up, condensed into one place).
4. The business logic calls the interface, never the discriminator.

**Runtime characteristics are identical.** If/else does a procedural lookup, switch uses a compiler-built jump table, polymorphic dispatch uses a vtable — similar performance.

**What you gain:**
- The high-level business code no longer transitively depends on every low-level case.
- Each case is its own named method, not an indented block within a branch.
- New cases = new classes (OCP).
- Independent deployment becomes possible: the high-level module and each implementation can live in separate components.

**When not to apply:** if the switch is small, stable, and not type-based (e.g., processing a small enum of flags in one place), leaving it as a switch is fine. The rule is "factor out switches on *type*," not "destroy every conditional."

---

## The Tell-Don't-Ask Style

Alan Kay's original OO conception: objects as cells in a biological system.

> "Neurons are tellers, not askers. Hormones are tellers, not askers. In biological systems, communication was half-duplex."

Instead of:
```
if account.getBalance() < amount:
    throw InsufficientFunds
account.setBalance(account.getBalance() - amount)
```

Say:
```
account.withdraw(amount)  // account decides if it can, and how
```

The caller stops interrogating state and deciding. The object owns the decision. This is what Law of Demeter is a weak shadow of — the deeper principle is that state should not leak out of objects.

---

## Loops and State Machines

From the 2020 "Loopy" post. Any program with nested loops can be refactored step-by-step into a Turing-style finite state machine, with tests passing at every step. This is a useful mental exercise: a nested loop is a state machine that a programmer wrote too compactly.

Practical takeaway: when a loop body is getting complex, consider extracting an explicit state (enum of states) and transitioning between them. Reads better than four nested `if`s; generalizes better; easier to test.

---

## Applying This in Practice

- **Default to OO + polymorphism** for business logic where types vary (entities, strategies, handlers). Polymorphism is the mechanism behind DIP, OCP, and Clean Architecture boundaries.
- **Default to data structures + free functions** for values, messages, and records that flow through the system. DTOs, events, API payloads, DB rows.
- **Keep the two species apart.** A "hybrid" that has both public fields and rich behavior usually gets the worst of both worlds.
- **FP is not an exception to SOLID.** Cohesion, SRP, DIP all still apply; you express them with namespaces, protocols, or type classes instead of classes.
