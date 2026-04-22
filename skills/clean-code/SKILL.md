---
name: clean-code
description: Apply Robert C. Martin's (Uncle Bob's) Clean Code, Clean Architecture, and Clean Craftsmanship principles when writing, reviewing, or refactoring code. Use this skill whenever the user asks to write new code of non-trivial size (functions, classes, modules, services), refactor or clean up existing code, review code for quality, design a module or system boundary, write tests, or whenever the user mentions "clean code," "clean architecture," "SOLID," "SRP," "OCP," "LSP," "ISP," "DIP," "TDD," "refactor," "code smells," "code review," "Uncle Bob," or "Robert Martin." Also engage proactively when producing or examining code that shows poor naming, long functions (>20 lines), deep nesting, unclear abstractions, duplicated logic, switch/if-else chains that should be polymorphic, missing tests, leaky boundaries, or frameworks bleeding into business logic — even if the user did not explicitly ask for a cleanup. Do not wait for magic words; if you are writing or touching code, consult this skill.
---

# Clean Code (Uncle Bob)

This skill codifies the principles that Robert C. Martin teaches across *Clean Code* (2008), *Clean Architecture* (2017), *Clean Craftsmanship* (2021), his blog at blog.cleancoder.com, the older wiki at butunclebob.com, his Google Sites articles, and his courses at cleancoder.com. It applies during code generation, review, refactoring, and system design.

## Core Philosophy

Three mental anchors to carry into every edit:

1. **Code is read far more than written.** The ratio is well over 10:1. Optimize for the reader — future teammates, and your future self.
2. **The Boy Scout Rule.** Leave every module cleaner than you found it — even if just by renaming one variable or extracting one tiny function.
3. **The only way to go fast is to go well.** Dirty code slows the whole team down. "We'll clean it up later" rarely happens, and productivity collapses into the Productivity Roller-Coaster or the Grand-Redesign Myth. Clean as you go, always.

Some quotes from other practitioners Uncle Bob cites:

- "Clean code is simple and direct. Clean code reads like well-written prose." — Grady Booch
- "Clean code always looks like it was written by someone who cares." — Michael Feathers
- "You know you are working on clean code when each routine you read turns out to be pretty much what you expected." — Ward Cunningham

## How to Use This Skill in a Session

When generating, reviewing, or refactoring code, work in this order:

1. **Name first.** Before writing a function body, confirm the name tells you what it does and why. If you cannot name it, you do not yet understand it.
2. **Extract till you drop.** "A function does one thing if, and only if, you cannot extract another function from it." Keep extracting until you cannot.
3. **Keep diffs honest.** When refactoring, do not also change behavior. When adding a feature, refactor *before* or *after*, never *during*.
4. **Prefer tests first** for non-trivial logic. If infeasible, write them immediately after. See [references/tdd.md](references/tdd.md).
5. **Respect boundaries.** Business rules must never depend on frameworks, databases, or UIs. See [references/architecture.md](references/architecture.md).
6. **Prefer polymorphism to conditionals** for anything that varies by type — place if/else/switch in a factory that creates polymorphic objects. See [references/paradigms.md](references/paradigms.md).
7. **Reread as a stranger.** Before declaring a task done, reread the code as if you had not written it.

## Deeper References

When the task calls for it, load the matching reference file:

- **[references/solid.md](references/solid.md)** — The five SOLID principles (SRP, OCP, LSP, ISP, DIP), their origins in Parnas (1972), Meyer (1988), Liskov (1987), their 2020 re-affirmation, and the component principles (REP, CCP, CRP, ADP, SDP, SAP). Load when designing a class, module, or microservice boundary.
- **[references/architecture.md](references/architecture.md)** — Clean Architecture: the Dependency Rule, concentric layers, Screaming Architecture, why "the database is a detail," Ivar Jacobson's use-case foundation. Load when structuring a new service, deciding what a microservice should own, or untangling framework coupling.
- **[references/tdd.md](references/tdd.md)** — The Three Laws of TDD, F.I.R.S.T., canonical test taxonomy (unit/acceptance/integration/system/micro/functional), test doubles, Chicago vs. London schools, fragile tests, the Transformation Priority Premise, the Cycles of TDD. Load when writing or reviewing tests.
- **[references/paradigms.md](references/paradigms.md)** — The three programming paradigms (structured, OO, functional), the reductionist definitions Uncle Bob uses for each, the Data/Object Anti-Symmetry (why DTOs are not objects), polymorphism as the heart of OO, if-else-switch refactoring, why FP and OO are orthogonal not exclusive. Load when the task involves choosing between procedural and OO style, writing code in a functional language, refactoring switch statements, or handling persistence.
- **[references/craft.md](references/craft.md)** — The craftsmanship ethic: mess vs. technical debt, Martin's First Law of Documentation, Saying No, estimation, pairing guidelines, "Going Fast" vs. "Speed Kills," the "Screaming Architecture" mindset applied to whole projects. Load when the task raises professional-judgment questions.
- **[references/oath.md](references/oath.md)** — The Programmer's Oath. Load when the task raises a question of professional responsibility (shipping under pressure, accumulating "temporary" hacks, padding estimates, degrading code to hit a deadline).

The remaining sections are the core rulebook for code at the function and class level. Scan them against anything you produce.

---

## 1. Meaningful Names

Names are the single highest-leverage lever for readability. From Tim Ottinger's naming rules, expanded in the book:

- **Use intention-revealing names.** `int d;` → `int elapsedTimeInDays;`. Names should answer: *What is this? Why does it exist? How is it used?*
- **Avoid disinformation.** Don't call something `accountList` unless it truly is a List. Don't use lowercase `l` or uppercase `O` as variable names (look like 1 and 0).
- **Make meaningful distinctions.** `productInfo` vs. `productData` is noise. `a1`, `a2`, `a3` is a red flag.
- **Use pronounceable, searchable names.** `genymdhms` is bad. Single letters are acceptable only for tiny local scopes.
- **Class names are nouns** (`Customer`, `WikiPage`, `AddressParser`). **Method names are verbs** (`postPayment`, `deletePage`, `save`).
- **Do not encode types.** Skip Hungarian notation, `m_` prefixes, `I` prefixes for interfaces.
- **Ubiquitous language.** Use the business domain's vocabulary. If the domain says "policyholder," do not name it `user`.
- **Pick one word per concept.** Standardize `fetch` vs. `retrieve` vs. `get`. Same for `controller` vs. `manager` vs. `driver`.
- **Add meaningful context, and no more.** Scattered `firstName`/`street`/`city` need an `addr_` prefix or an `Address` type.

## 2. Functions

> First rule: functions should be small. Second rule: smaller than that.

- **Target ~20 lines, often far fewer.** If you cannot see the whole function without scrolling, it is too long.
- **Do one thing.** *Operational definition:* a function does one thing if, and only if, you cannot extract another function from it (Uncle Bob, "Extract till you drop," 2009).
- **One level of abstraction per function.** The Step-Down Rule: public high-level functions at top, calling slightly lower-level helpers, and so on. Reading top to bottom should feel like descending a staircase.
- **Extract till you drop.** Most programmers stop far too early. Extract until you cannot.
- **Descriptive names beat short names.** A long descriptive name is better than a long descriptive comment.
- **Few arguments.** 0 ideal. 1–2 fine. 3 suspect. 4+ almost always means a struct or a split.
- **No flag arguments.** `render(true)` is terrible. Split into `renderForSuite()` and `renderForSingleTest()`.
- **No hidden side effects.** A function named `checkPassword` must not also initialize a session.
- **Command-Query Separation.** A function either *does* something or *answers* something, never both.
- **Tell, don't ask.** Alan Kay's original OO concept: cells in a biological system tell each other what to do; they do not ask for state and decide. Neurons, hormones — all tellers.
- **Prefer exceptions (or Result types) to error codes.**
- **Extract try/catch bodies.** Each should be a single function call.
- **Avoid switch statements** in business logic. See [references/paradigms.md](references/paradigms.md) for the factory+polymorphism pattern.
- **Don't Repeat Yourself.** Duplication is the root of many evils.

**Example — doing one thing:**

Bad:
```
def process_order(order):
    if not order.items:
        raise ValueError("Empty")
    total = sum(i.price * i.qty for i in order.items)
    total *= 1.1  # tax
    send_email(order.customer, f"Total: {total}")
    db.save(order, total)
    return total
```

Clean:
```
def process_order(order):
    validate(order)
    total = calculate_total_with_tax(order)
    notify_customer(order, total)
    persist(order, total)
    return total
```

## 3. Comments

> "Don't comment bad code — rewrite it." — Brian Kernighan

Every comment represents a failure to make the code self-explanatory. Before writing a comment, ask: *can I rename or extract to make this unnecessary?*

**Good comments (rare but valuable):**
- Legal headers (when required).
- Informative comments you cannot encode in names (regex explanations, format specs, wire protocol details).
- Explanation of **intent** — *why*, not *what*. Why this ordering, why this tradeoff, why this workaround.
- Clarification of obscure arguments or return values you cannot rename.
- Warnings of consequences ("this test takes two hours to run").
- TODOs — prune regularly; a stale TODO list is worse than none.
- Public API documentation (Javadoc, rustdoc, TSDoc, etc.).
- **Genuine complexity that resists expression in code.** Uncle Bob's own "Necessary Comments" (2017) example: a "choked function" (throttled cache wrapper) required a timing diagram in the test comments because no amount of naming or extraction could communicate the six interleaved test cases. Rare — but it happens.

**Bad comments — delete on sight:**
- Mumbling (written for yourself, unclear to others).
- Redundant (restates the code).
- Misleading (out of date or wrong — actively harmful).
- Mandated (comment-every-function policies produce noise).
- Journal/changelog (that's what git is for).
- Noise (`// default constructor`).
- Commented-out code (delete it; git remembers).
- Closing-brace comments (`} // end if`) — your function is too long.
- Attributions (`// added by Rick`) — `git blame` exists.

**Martin's First Law of Documentation** (from *Agile Software Development: PPP*): Produce no document unless its need is immediate and significant. Note the scope: *documents*, not code comments. Agile is not the rejection of documentation — that is "flawed religious behavior." Documentation earns its keep on a prioritized, ROI basis.

## 4. Formatting

**Vertical formatting — the newspaper metaphor:**
- Top of file: high-level concept. Details grow as you scroll.
- Related concepts stay vertically close.
- Dependent functions: caller above callee (the Step-Down Rule).
- Blank lines separate concepts, not pad.

**Horizontal formatting:**
- Keep lines readable (~100–120 chars).
- Do not align assignments artificially.
- Use indentation consistently; never collapse a multi-branch `if`/`while` onto one line.
- Follow the team's standard. Consistency within a project beats any individual preference.

**Indentation is an abstraction-level signal.** Ideal functions have zero indentation beyond the function body; one or two levels (one if/while, one try) is acceptable. Deeper nesting usually means you have missed an extraction.

## 5. Objects and Data Structures

**Data/Object Anti-Symmetry** (Chapter 6, *Clean Code*):

- **Object:** a set of functions that operate on **implied** data. Data exists but is hidden.
- **Data structure:** a set of data elements operated on by **implied** functions. Data is exposed; functions are not specified by the structure itself.

These are **complements**, not siblings. Consequences:

- DTOs are data structures, not objects.
- Database tables are data structures, not objects.
- "ORM" is a misnomer — there is no real mapping between tables and objects.
- **The axis of expected change determines the style.** If you expect more new functions than new types, prefer procedural style (data structures + functions). If you expect more new types than new functions, prefer OO (classes + polymorphism). The Visitor pattern bridges the two.

Other rules:

- **Law of Demeter — don't talk to strangers.** A method `f` of class `C` should only call methods of: `C` itself, objects it creates, objects passed as arguments, or objects it holds as fields. Avoid train wrecks: `a.getB().getC().doSomething()`.
- **Tell, don't ask.** Instead of asking for state and deciding, tell the object to do the work.

More on this in [references/paradigms.md](references/paradigms.md).

## 6. Error Handling

- **Use exceptions (or Result types), not return codes.**
- **Write try-catch-finally first** when an operation can fail. It defines the transactional scope.
- **Provide context with exceptions.** Wrap third-party exceptions in your own types.
- **Define exception classes by the needs of the caller**, not by implementation detail.
- **Do not return null.** Return empty collections, use Option/Result/Maybe, or throw. Null checks pollute callers.
- **Do not pass null.** If a function cannot handle null, do not accept it. Fail fast at the boundary.

## 7. Boundaries

- **Wrap third-party APIs in adapters.** Your code talks to the adapter, not the library. Localizes changes when the library upgrades or is replaced.
- **Write learning tests** when exploring a new library: small, focused tests that probe its behavior. When the library upgrades, they tell you what broke.
- Keep boundaries clean so replacing a dependency is a localized change, not a project-wide rewrite.
- The big structural story is in [references/architecture.md](references/architecture.md).

## 8. Tests

See [references/tdd.md](references/tdd.md) for the full treatment. Essentials:

**Three Laws of TDD:**
1. Do not write production code until you have a failing test.
2. Do not write more of a test than is sufficient to fail.
3. Do not write more production code than is sufficient to pass.

**F.I.R.S.T.:** Fast, Independent, Repeatable, Self-validating, Timely.

**Michael Feathers' definition of legacy code:** *Legacy code is code without tests.* Uncle Bob calls Feathers's *Working Effectively with Legacy Code* "the only book I know of that addresses this topic."

Test code is first-class. Hold it to the same clarity bar as production code.

## 9. Classes

- **Small.** For functions we counted lines. For classes we count **responsibilities**.
- **Single Responsibility Principle.** The formulation has evolved: "do one thing" → "one reason to change" → most recently (Clean Architecture, 2017) "responsible to one, and only one, **actor**" (where actor is a person or tightly coupled group). See [references/solid.md](references/solid.md).
- **Cohesion.** Methods should use most of the instance variables. Low cohesion = two classes in a trench coat.
- **Organize for change.** Isolate volatile concepts behind interfaces so changes do not ripple.
- **Class organization order:** public static constants → private static variables → private instance variables → public functions → private helpers (grouped with their public caller).

## 10. Systems

- **Separate construction from use.** Startup code (wiring dependencies) lives in one place; business logic does not touch it.
- **Dependency injection** over hardcoded `new` expressions deep in business logic.
- **Cross-cutting concerns** (logging, transactions, security, metrics) belong in middleware/aspects/interceptors, not scattered through the domain.
- Let architecture **emerge** as the system grows, but defend the seams — the places where modules plug together — at every stage.
- See [references/architecture.md](references/architecture.md).

## 11. Emergent Design — Kent Beck's Four Rules

A design is *simple* if, in priority order, it:

1. **Runs all the tests.**
2. **Contains no duplication.**
3. **Expresses the intent of the programmer.**
4. **Minimizes the number of classes and methods.**

Order matters. Never sacrifice test coverage to reduce class count.

---

## 12. Code Smells — A Review Checklist

Scan for these before declaring code done.

**Function smells**
- Too many arguments (>3).
- Flag arguments (booleans that switch behavior).
- Selector arguments (enums that drive internal switches).
- Dead parameters, dead code paths.
- Obscure intent — body reads as a sequence of mystery steps.
- Misplaced responsibility — function lives on the wrong class/module.
- Inappropriate static — method should be polymorphic.

**Class smells**
- Feature envy (method uses another class's data more than its own).
- Large class / god class.
- Too many responsibilities.
- Inappropriate intimacy between classes.
- Lazy class — no longer pulls its weight.

**General smells**
- **Duplication** — the #1 smell; hunt it everywhere.
- Magic numbers or strings — extract named constants.
- Inconsistent names for the same concept.
- Artificial coupling — things glued together that don't belong.
- Negative conditionals (`if (!isNotEmpty)`) — invert.
- **If-else or switch chains on type** — replace with factory + polymorphism; see [references/paradigms.md](references/paradigms.md).
- Dead code.
- Vertical separation — variables declared far from use.
- Boundaries violated — business logic importing framework classes, entities reaching the DB.

**Name smells**
- Non-descriptive (`data`, `info`, `handle`, `process`).
- Names not matching level of abstraction.
- Mental mapping required (decode `r`, `q`, `tmp`).
- Encoded names (Hungarian, type prefixes).
- Side info stuffed into names ("the `u` here is because…").

**Test smells**
- Insufficient tests.
- Skipped or ignored tests accumulating.
- Tests dependent on execution order.
- Tests that test the framework, not your code.
- Slow tests (they will stop being run).
- Over-mocking — tests break on refactor without any real regression.

---

## A Note on Disagreement

Clean Code is not scripture. Uncle Bob himself has revised definitions across his career (SRP has three formulations; LSP was initially taught as about inheritance and later clarified as about subtyping). He has also publicly recommended John Ousterhout's *A Philosophy of Software Design* (2022) while noting disagreements with Ousterhout on two key Clean Code points:

- Ousterhout prefers larger functions with "deep implementations behind narrow interfaces."
- Ousterhout advocates more use of comments.

These are honest, ongoing debates. The skill's default aligns with Uncle Bob; you are expected to think about the tradeoffs, not apply the rules blindly. When a codebase's structure makes the opposite choice more readable for the reader-in-context, the reader wins.

## One More Thing

Clean code is not a destination — it is a **practice**. Every function is an opportunity to practice. The single most important lesson is not any rule; it is the **attitude of caring enough to leave the code better than you found it**.

The professional commitment behind all of this is captured in [references/oath.md](references/oath.md) and elaborated in [references/craft.md](references/craft.md).
