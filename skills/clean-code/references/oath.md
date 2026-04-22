# The Programmer's Oath

When to load this reference: when the task raises a question of professional responsibility — shipping under pressure with known defects, accumulating "temporary" hacks, padding estimates, degrading code to hit a deadline, or pushing back on a manager who is asking for the impossible.

In 2015, Uncle Bob proposed an oath for programmers, modeled loosely on the Hippocratic Oath, that captures the professional commitments behind Clean Code, Clean Architecture, and Agile practice. The oath exists because software increasingly runs civilization — cars, medical devices, infrastructure, money — and the people who write that software carry a corresponding weight of responsibility. His 2019 post "737 Max 8" is the most concrete illustration of why this matters: what happens when mission-critical software ships without the oath.

---

## The Oath

*In order to defend and preserve the honor of the profession of computer programmers, I promise that, to the best of my ability and judgement:*

1. **I will not produce harmful code.** Not code known to be defective. Not code that degrades the product. Not code that lies.
2. **The code I produce will always be my best work.** I will not knowingly allow defective behavior or defective structure to accumulate.
3. **I will produce, with each release, a quick, sure, and repeatable proof that every element of the code works as it should.** Automated tests that run fast and tell the truth.
4. **I will make frequent, small releases** so that I do not impede the progress of others.
5. **I will fearlessly and relentlessly improve my creations at every opportunity.** I will never degrade them. Each commit leaves the system at least as clean as I found it — preferably cleaner.
6. **I will do all that I can to keep the productivity of myself and others as high as possible.** I will do nothing that decreases that productivity. This is why clean code matters: dirty code taxes every future developer who reads it.
7. **I will continuously ensure that others can cover for me, and that I can cover for them.** No knowledge silos. No indispensable person. Shared ownership of the codebase.
8. **I will produce estimates that are honest** both in magnitude and precision. **I will not make promises without certainty.** "I don't know yet" is a professional answer. Padding to please is not.
9. **I will never stop learning and improving my craft.** Programming is a practice, not a credential.

---

## How This Oath Informs the Skill

The oath is not abstract ethics — it is directly wired into the practices that Clean Code, Clean Architecture, and TDD embody.

- **"Not produce harmful code"** → No flag arguments hiding branches, no null returns that hide failures, no functions with secret side effects. Clean Code, Chapter 7 (Error Handling). Mission-critical relevance: the 737 MAX is what happens when software that can kill people is built without the oath.
- **"Best work … will not allow defective structure to accumulate"** → the Boy Scout Rule. A mess is not technical debt (see [craft.md](craft.md)).
- **"Quick, sure, repeatable proof"** → TDD and F.I.R.S.T. tests. See [tdd.md](tdd.md).
- **"Frequent small releases"** → continuous integration and the Agile practices. If a release takes a day, releases are infrequent by economic necessity; fix the release process, not the schedule.
- **"Fearlessly improve"** → only possible with a test net. Without tests, every change is a gamble, so code rots by default. *Legacy code is code without tests* (Feathers).
- **"Keep productivity high"** → the whole argument for clean code. Dirty code slows the team down. "We'll clean it up later" is almost always a lie.
- **"Others can cover for me"** → pairing, code review, shared ownership, honest naming. See [craft.md](craft.md). If only one person understands the billing module, the billing module is a liability.
- **"Honest estimates"** → ranges, not points. Three-point estimates (optimistic, nominal, pessimistic). "I cannot know yet, I will know more after the spike" is honest; a number pulled from the air to calm a manager is not.
- **"Never stop learning"** → the craftsmanship attitude. Every function is practice.

---

## The Underlying Argument: Professionalism Is Honor

From Uncle Bob's 2009 Rails Conf keynote "Why the sea is boiling hot":

> "Professionalism does not mean rigid formalism. Professionalism does not mean adhering to bureaucracy. Professionalism is honor. Professionalism is being honest with yourself and disciplined in the way you work. Professionalism is not letting fear take over."

The oath is not a rulebook; it is a set of promises about the kind of engineer you intend to be. When pressure mounts and shortcuts beckon, those promises are what keep the work honest.

---

## The 737 MAX Argument

From "737 Max 8" (2019). Software increasingly operates in domains where failure kills. Cars, medical devices, aircraft, infrastructure control systems. The argument Uncle Bob makes:

- Our industry still doesn't act like a profession. There are no widely-enforced standards for competence. Anyone can ship anything.
- When failures in a civilian product only mean frustrated customers, this is tolerable. When failures mean dead people, it is not.
- Either the industry disciplines itself, or governments will do it for us — and government-imposed discipline will be crude and bureaucratic compared to what we could choose.
- The oath is a voluntary first step.

For Claude-written code, this usually doesn't feel immediate. But the oath's standards apply to any code that runs. A user asking Claude to "just ship it, we'll fix bugs later" in a payment system is asking Claude to contribute to harm the user probably hasn't imagined.

---

## When to Cite This in a Session

- **User is asking Claude to skip tests "just this once."** Clean code practice says no — the "just this once" mindset is how codebases accumulate the slow-rotting debt the oath forbids.
- **User is asking Claude to estimate something the code cannot yet answer.** Honest ranges beat false precision. "I do not know, let me find out" is honest.
- **User is under deadline pressure and proposes shipping code with known defects.** The oath is unambiguous: unknown defects happen to everyone; knowingly shipped ones are a professional failure.
- **User asks Claude to produce code that lies** — silently swallows errors, hides side effects, misrepresents state. Decline and explain why.
- **A proposed change would make future developers' lives worse** for a short-term gain. Promise 6 of the oath is explicitly about not decreasing others' productivity.
- **User is shipping to a safety-critical domain** and cutting corners. Name the risk explicitly; the user may not have considered it.

The oath is not a stick to beat users with. It is a reminder of the stakes that clean practice is trying to address, and a useful touchstone when a decision has no obvious technical answer. Lead with helpfulness; invoke the oath when helpfulness would mean producing work Claude should not be producing.

---

## Related Reading

- [craft.md](craft.md) — the surrounding ethic in more detail: mess vs. debt, saying no, estimation, pairing, the "tricky bit."
- Uncle Bob's *The Clean Coder* (2011) — the book-length treatment of professional ethics in software. Unlike *Clean Code*, it is about behavior rather than technique.
- Uncle Bob's *Clean Craftsmanship* (2021) — the discipline-focused sequel to *Clean Code*, integrating TDD, refactoring, simple design, and the oath.
