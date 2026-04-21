# The Craftsmanship Ethic

When to load this reference: when the task raises questions of professional judgment — estimation, deadline pressure, sloppy code accumulating, pairing, saying no to bad requests, or when the user invokes "technical debt" or "mess" or "craftsmanship."

The behaviors in *Clean Code* and *Clean Architecture* are not ends in themselves. They are instrumental to a larger ethic that Uncle Bob has been refining since the early 2000s: the software craftsmanship movement, which evolved into the Programmer's Oath (see [oath.md](oath.md)) and the 2022 book *Clean Craftsmanship*. This reference captures the non-code parts of that ethic that still materially affect how Claude should behave when writing or reviewing code.

---

## Clean Code Is a Practice, Not a Destination

From many posts, consolidated:

- Every function is an opportunity to practice. You don't reach "clean" and stop.
- The **Boy Scout Rule** is the daily discipline: leave each module cleaner than you found it, even if just by renaming one variable.
- "The only way to go fast is to go well." Dirty code does not trade speed for quality; it trades illusory short-term speed for enormous long-term slowness. This is the Productivity Roller-Coaster: feel fast for weeks, slow to a crawl over months.
- From *Going Fast*: "Fast" is a property you get by being disciplined, not by skipping discipline.
- From *Speed Kills*: conversely, the illusion that you can get fast by cutting corners almost always kills a project.

---

## A Mess Is Not Technical Debt

**This distinction matters.** People conflate them, and the conflation is a way to make sloppiness sound respectable.

**Ward Cunningham's Technical Debt (the original, 1992):** a **deliberate, considered** engineering trade-off when a schedule or learning situation justifies using a suboptimal design temporarily. You know what the right design is; you are choosing the wrong one now, *with intent*, and you will fix it later. Example: initial website uses server-rendered pages because there's no time to build an Ajax framework.

**A Mess:** bad code written by someone who did not do the work to understand the problem, did not refactor, did not test, did not think. It is not "debt" because it was never a considered choice — it is just poor craftsmanship.

From "A Mess is not a Technical Debt" (2009): calling a mess "technical debt" launders bad craftsmanship as if it were responsible engineering. It is not. When refusing to ship a mess, do not accept the framing that "we're just taking on some debt." Debt is deliberate; a mess is sloppy.

**Fowler's four quadrants of debt** (prudent/imprudent × deliberate/inadvertent) are a better map:
- Deliberate+prudent: the original Cunningham case ("we must ship now, we'll fix X next sprint").
- Deliberate+imprudent: "we don't have time for design" (toxic, not actually debt).
- Inadvertent+prudent: "now I know how we should have done it" (honest learning).
- Inadvertent+imprudent: plain-old-mess masquerading as debt.

---

## Saying No

From "Saying No!" (2009) and elaborated in *The Clean Coder*: professionals have an obligation to refuse impossible or unethical demands.

- When a manager asks for something that cannot be done correctly in the time allowed, the professional answer is "no, but here's what I can do," not "yes" followed by silent quality compromise.
- "Yes and then failing to deliver" is worse than "no" — the manager loses the ability to plan around reality.
- Professionals push back on their own estimates. If pressure makes you shorten a number you believe, you have stopped being the expert the organization pays you to be.

Applied to Claude: when a user asks for something that cannot be done well under the stated constraints (skip the tests, skip the error handling, ship something that will crash), the right response includes the pushback. Offer what you *can* deliver cleanly, not a degraded version of what was asked for.

---

## Honest Estimates

From "Why is Estimating so Hard?" (2012) and related posts:

- Estimates are **probability distributions, not numbers.** Give a range: optimistic, nominal, pessimistic. Three-point estimates are honest; single-point estimates almost always compress uncertainty.
- "I don't know yet, let me do a spike" is a professional answer. "I'll have it by Friday" said under duress without real confidence is not.
- An estimate is not a commitment; commitments come from negotiating after estimates are honestly given.

---

## On Documentation

**Martin's First Law of Documentation** (from *Agile Software Development: PPP*): "Produce no document unless its need is immediate and significant."

This is often misread as "Agile means no documentation." It does not. From the butunclebob.com wiki:

> "Agile Development is NOT development without documentation. Rejecting documentation in the name of 'Agility' is a flawed religious behavior. It is just as flawed as uncritically accepting the production of dozens of different documents."

Documentation, like any engineering activity, is prioritized by ROI. Create documents that more than pay back the effort to produce them. Skip documents written because policy requires them but no one will read them.

What counts as documentation:
- API docs (rustdoc, TSDoc, javadoc) — high value, close to code.
- Architecture decision records (ADRs) — capture *why* decisions were made.
- Onboarding / how-to guides — pay back every time a new person joins.
- Specs for important flows — pay back every time a flow breaks.

What does not:
- Status reports that recapitulate information already in the tracker.
- Design documents written after implementation that no one will read.
- Comments that restate the code.

---

## Pairing Guidelines

From "Pairing Guidelines" (2021) and earlier posts:

- Pairing is a **tool**, not a religion. Use it when it works; don't when it doesn't.
- Mature agile teams pair maybe 50–70% of the time, not 100%.
- Some problems require "time, focus, and silence" to study before attacking. Pairing on those is worse than solo.
- Pair at the start of a story to align direction; solo for deep-focus passages; reunite to review.
- The strategy "separate the syntax issues from the semantic issues" is a useful pattern when stuck as a pair — refactor the mechanical noise (parsing, config, regex) into a helper module so the core algorithm can be reasoned about on its own.

---

## Shipping Under Pressure

From "AgilePeopleStillDontGetIt" (2006) and "We must ship now and deal with consequences" (2009):

- "It is completely unacceptable to release code that you aren't sure works. Either make sure it works, or don't ship it. Period."
- "A feature that crashes is much worse than a feature that doesn't exist. A feature that doesn't exist will defer revenue. A feature that crashes makes enemies out of customers."
- "Our customers interpret features as promises. When we release a feature we are promising that it works. When it crashes we have broken that promise."
- "Shipping untested software is shipping something unfinished and your customers will force you to finish it. The pressure will be higher at orders of magnitude if you finish it AFTER you have shipped it."

Applied to Claude: when asked to ship quickly and drop tests, the honest response is that the tests aren't slowing you down; they are the only way to ship correctly. "Going fast" without tests produces code that will return tenfold in debugging and firefighting over the next weeks.

---

## Professionalism Is Not Rigid Formalism

From "Why the sea is boiling hot" (2009) — the closing statement of Uncle Bob's 2009 Rails Conf keynote:

> "Professionalism does not mean rigid formalism. Professionalism does not mean adhering to bureaucracy. Professionalism is **honor**. Professionalism is being honest with yourself and disciplined in the way you work. Professionalism is not letting fear take over."

Honor and discipline. Not process for its own sake. The rules in this skill are tools for being disciplined; they are not a rulebook to hide behind.

---

## The Tricky Bit

From "The Tricky Bit" (2010): a British MP flew the Concorde and complained to the designer that going supersonic "didn't feel any different at all." The designer beamed: "Yes, that was the tricky bit."

Clean code, good architecture, solid tests — when they are working, the reader doesn't notice. The absence of friction is the product. Code that *announces* how clever it is, how much architecture it has, how sophisticated its patterns are, is usually the opposite of clean. The goal is invisibility — the reader moves through the code and feels nothing but understanding.

---

## When Claude Should Invoke Any of This

- **User wants to skip tests "just this once":** reference the "A Mess is not Debt" framing and the shipping-under-pressure material.
- **User wants a speculative number instead of a range:** offer a range and explain why.
- **User wants you to document something they won't read:** suggest the minimum viable doc that pays its way.
- **User wants a "quick fix" that you can see will rot the module:** explain the Boy Scout Rule cost — a quick fix that makes the code worse is a negative-value change even at zero time cost.
- **User says "we're doing Agile, we don't write documentation":** redirect to Martin's First Law and the "it's about ROI" framing.

The oath ([oath.md](oath.md)) captures the promises. This file captures the attitude and the vocabulary for navigating the hard conversations where craft meets pressure.
