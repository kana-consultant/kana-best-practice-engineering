# Test Driven Development

When to load this reference: when writing new tests, reviewing tests, debugging brittle tests, dealing with legacy code that resists testing, or deciding on a testing strategy for a module.

Tests are the safety net that makes fearless refactoring possible. Without that net, every change is a gamble; with it, every change can be confident. Tests are also the most precise, executable documentation a system will ever have.

**Michael Feathers's definition of legacy code:** *Legacy code is code without tests.* Uncle Bob adopted this definition and it underpins the TDD practice.

---

## The Three Laws of TDD

1. **You are not allowed to write any production code unless it is to make a failing unit test pass.**
2. **You are not allowed to write any more of a unit test than is sufficient to fail — and compilation failures are failures.**
3. **You are not allowed to write any more production code than is sufficient to pass the one failing unit test.**

The loop is measured in seconds, not minutes. Write a line or two of test, see it fail, write a line or two of production, see it pass, repeat. This is the **nano-cycle**.

**Why these rules:**

- **Debugging time plummets** — you were never more than 60 seconds away from working code.
- **Tests are automatic documentation** that cannot fall out of sync with the system.
- **Design improves** because code written to be testable is naturally decoupled.
- **Refactoring becomes fearless** because the net catches regressions instantly.

This is double-entry bookkeeping for software. Every behavior is stated twice — once in the test, once in the code — and they must agree.

---

## F.I.R.S.T. — Clean Tests

Clean tests are:

- **Fast.** Slow tests will stop being run. If a suite takes 10 minutes, people will commit without running it. 15-minute CI feedback is too slow for the TDD loop.
- **Independent.** No test depends on another. Any test can run alone, in any order.
- **Repeatable.** Same result in every environment — laptop, CI, staging. If a test depends on the network, wall clock, or shared database, it is flaky and must be fixed.
- **Self-validating.** Pass or fail. No manual inspection.
- **Timely.** Written *just before* the production code they cover — not "when we have time."

Test code is first-class. Hold it to the same clarity bar as production code. When tests rot, production code rots.

---

## Canonical Test Definitions (First-Class Tests, 2017)

The industry has been sloppy about what "unit," "integration," "acceptance," etc. mean. Uncle Bob's proposed taxonomy:

- **Unit Test.** Written by a programmer, for a programmer. Ensures production code does what the programmer expected. Sometimes called **programmer test** or **micro-test**.
- **Acceptance Test.** Written by the business (or a BA/QA representing the business). Ensures production code does what the business expects. Sometimes called **customer test**.
- **Integration Test.** Written by architects or technical leads. Ensures a sub-assembly of system components operates correctly. **These are plumbing tests, not business-rule tests** — rules are already verified by unit and acceptance tests.
- **System Test.** An integration test for the whole integrated system.
- **Micro-test** (Mike Hill / @GeePawHill). A unit test at very small scope — tests a single function or small group.
- **Functional Test.** A unit test at larger scope, with mocks for slow components.

> "Integration tests do not test business rules. Those rules have already been tested, once by programmer (unit) tests, and again by customer (acceptance) tests. Integration tests test the plumbing and choreography of the components." — Uncle Bob (Twitter, 2019)

**Implication for Claude when writing tests:** Know which kind of test you are writing and don't couple it to the wrong kind. If you're asked to "add tests" for a pure function, write unit/micro tests. If you're asked to "test the API works end-to-end," that's integration/system. Don't test business rules in an integration test — the rules should already have unit tests.

---

## Test Structure

Use one of these structures; be consistent.

- **Arrange / Act / Assert** — set up context, perform action, check result.
- **Given / When / Then** — same thing in BDD vocabulary.
- **Build / Operate / Check** — same thing, different vocabulary.

One *concept* per test. Often one assertion, but "one concept" is the real rule — several assertions verifying the same behavior are fine.

### Test Naming

Name the test for what it verifies about behavior, not for the method. `returns_empty_list_when_given_empty_input` beats `test_filter_1`. If the name runs long, the test is probably doing more than one thing.

---

## Test Doubles — The Hierarchy

Adapted from Gerard Meszaros's *xUnit Patterns*, with Uncle Bob's gloss. Each is a degree of sophistication above the last.

- **Dummy.** Passed around but never used. Fills a parameter slot.
- **Stub.** Returns canned answers. No logic.
- **Spy.** A stub that records the calls it received.
- **Mock.** A spy with expectations built in: set up *before* the act, verified *after*. Fails if expected interactions didn't happen.
- **Fake.** A working implementation with production-unfit shortcuts — e.g., in-memory repo that stands in for a real database.

Pick the lowest-sophistication double that does the job. A mock where a stub would suffice adds coupling and fragility.

**Uncle Bob hand-rolls most of his Java mocks** ("Manual Mocking," 2009) rather than using mockito, to keep explicit control over ceremony. This is a taste preference, not a rule, but his reasoning (less magic, clearer test code) is worth knowing.

---

## Chicago vs. London (State-ism vs. Mockism)

Two schools of TDD.

- **Chicago / Classical / State-ist.** Test behavior through state. Exercise the object, assert on its final state (or collaborators' state). Minimal mocking. Less coupled to implementation detail.
- **London / Mockist.** Test behavior through interactions. Mock collaborators; assert on calls. More explicit about collaboration but more coupled to it.

**Practical guidance:** Use Chicago for value objects, algorithms, internal logic. Use London at **boundaries** — where the code coordinates external collaborators. Never mock what you own when you could exercise it directly; mock (or fake) what you do not own when the real thing would make the test slow or flaky.

---

## Fragile Tests

Tests that break without a real regression are worse than no tests — they train developers to ignore the suite. Known causes:

- **Interface sensitivity.** Tests break because a signature changed, not behavior. Often a sign of excessive mocking.
- **Behavior sensitivity.** Tests break because an unrelated behavior changed. A sign of poor isolation.
- **Data sensitivity.** Tests break because shared fixtures changed. Fix by making tests own their data.
- **Context sensitivity.** Tests pass locally, fail in CI. Remove environmental coupling: clock, network, filesystem, time zone.
- **Over-specification.** Tests assert on more than the behavior under test — internal call order, private fields, log output. Assert on what the *user of the code* would observe.

A fragile test is a design signal — usually a missing abstraction, a leaky boundary, or an over-eager mock.

"Skilled TDDers understand that neither micro-tests, nor functional tests, nor acceptance tests should be coupled to the implementation of the system." — *First-Class Tests* (2017)

---

## As Tests Get More Specific, Code Gets More Generic

Uncle Bob's formulation (2009): tests are specifications. As you add tests, the specifications grow more specific. To satisfy them all, the production code must grow more *generic*. This is the inverse relationship that drives TDD-induced good design — the code gets pushed toward abstractions that cover many cases rather than one.

---

## The Transformation Priority Premise (TPP)

When making a failing test pass, there is a natural ordering of changes, simpler before more complex. Prefer earlier transformations when more than one would work:

1. `{} → nil` — no code → returning nil
2. `nil → constant` — return a constant
3. `constant → variable` — replace constant with a variable
4. `statement → statements` — add another statement
5. `unconditional → if` — introduce a branch
6. `scalar → array` — move from a single value to a collection
7. `array → container` — move to a richer collection type
8. `statement → recursion` — replace a statement with recursion
9. `if → while` — replace a branch with iteration
10. `expression → function` — extract a function
11. `variable → assignment` — introduce mutation

Using lower-priority transformations earlier creates needless complexity; using higher-priority ones later often indicates a design that could be simpler. TPP is a tiebreaker, not a law — but it usually guides tests toward algorithms that generalize cleanly.

---

## The Cycles of TDD

TDD operates at multiple time scales simultaneously. Working at only one scale produces bad software.

- **Seconds (Red-Green-Refactor).** The nano-cycle.
- **Minutes (Specific-to-Generic).** Tests grow more specific; code grows more generic.
- **Tens of minutes (Boundary).** Periodically step back and ask whether the module is still well-factored. Extract. Rename. Regroup.
- **Hours (Architecture).** Once a day or so, step back further: are the component boundaries still correct? Does the Dependency Rule still hold?
- **Days (Acceptance).** Acceptance tests (at the feature/use-case level) close the loop with the business.

Skipping the larger cycles is the most common failure mode. Red-Green-Refactor religiously, but never step back to reconsider architecture, and you end up with a suite of fine-grained tests wrapped around a tangled ball of mud.

---

## Testing Across Architectural Boundaries

- **The test boundary** is a first-class part of architecture. Tests live outside the system they test.
- **Do not couple tests to UI frameworks or databases.** If a test needs a browser to exercise a use case, the boundary between use case and UI is broken.
- **Legacy code strategy** (Feathers). Find a seam — a place where behavior can be varied without modifying code. Write a characterization test at that seam to pin down current behavior. Refactor behind the pin. Repeat.

Uncle Bob's position on test placement: "Don't test through UIs. Don't test through web servers. Test as close to the code as you can." — *Testing Like the TSA* (2017)

---

## Common Pitfalls

- **Writing tests after the fact.** Produces tests that confirm whatever the code happens to do, including the bugs. Much lower value than TDD.
- **Slow test suites.** If any unit test takes more than a fraction of a second, isolate it. Keep the unit suite fast and run integration tests separately.
- **Mocking what you own.** Prefer real objects for your own code.
- **Testing implementation details.** Refactors then break tests without any real regression, and people conclude "TDD gets in the way of refactoring." It doesn't — the tests were just wrong.
- **Skipping refactor.** Red-Green-… is not TDD. The third step is where design emerges.
- **Over-coverage religion.** Uncle Bob's ratio for some project types: 20% test-first, 80% test-after is acceptable for controllers/models/views (per *Testing Like the TSA*, 2017). The three laws are guidance for the hottest logic in the system, not dogma for every trivial accessor.
