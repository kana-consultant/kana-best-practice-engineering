# Sources

This skill was built from material crawled from the Uncle Bob source network you provided. This file is an honest accounting of what was fetched and what wasn't, so you can verify the provenance of any claim and follow up if something seems off.

## Fully read (body captured)

### Course outlines (cleancoder.com/files/)

- cleanCodeCourse.md
- cleanArchitectureCourse.md
- tdd.md
- advanced-tdd.md
- clean-agile.md
- immersion.md

### Blog posts (blog.cleancoder.com) — full or near-full body

- The Clean Architecture (2012-08-13)
- The Programmer's Oath (2015-11-18)
- The Single Responsibility Principle (2014-05-08, partial)
- The Open Closed Principle (2014-05-12, via search)
- OO vs FP (2014-11-24, via search)
- First-Class Tests (2017-05-05, via search)
- Testing Like the TSA (2017-03-06, via search)
- Test Contra-variance (2017-10-03, via search)
- Necessary Comments (2017-02-23)
- Solid Relevance (2020-10-18)
- if-else-switch (2021-03-06, via search)
- Screaming Architecture (2011-09-30, via search)
- A Little Architecture (2016-01-04, via search)
- Classes vs Data Structures (2019-06-16, via search)
- Functional Classes (2023-01-18, via search)
- Loopy (2020-09-30, via search)

### Other sources

- cleancoder.com/books (full — Uncle Bob's recommended-reading list with annotations)
- sites.google.com/site/unclebobconsultingllc/.../articles (index + inline excerpts of ~40 articles)
- sites.google.com/.../articles/one-thing-extract-till-you-drop (full body after fighting Google Sites' massive-nav rendering)
- butunclebob.com old-wiki pages via web_search:
  - ArticleS.UncleBob.PrinciplesOfOod (SRP evolution, component principles)
  - ArticleS.UncleBob.AgilePeopleStillDontGetIt (shipping untested code is unacceptable)
  - ArticleS.UncleBob.OnDocumentation (Martin's First Law of Documentation)
  - ArticleS.UncleBob.P2M2 (pairing guidelines)
  - ArticleS.UncleBob.IuseVisitor (Visitor pattern as SRP-preserver)
  - ArticleS.MichaelFeathers.LiskovSubstitutionInDynamicLanguages (LSP in dynamic languages)

## Titles only (index excerpts captured, body not fetched)

~120 additional blog.cleancoder.com posts — titles, dates, and (for ~30 of them) 1–3 sentence excerpts from Anthropic web_search results. Topics include: The Cycles of TDD, The Little Mocker, When to Mock, Monogamous TDD, Test Induced Design Damage?, The Transformation Priority Premise (+ three follow-ups), Three Paradigms, Why Clojure, FP Basics E1–E4, The Principles of Craftsmanship, The Humble Craftsman, Saying No, The Churn, The Lurn, NO DB, Clean Micro-service Architecture, Framework Bound, 'Interface' Considered Harmful, The Little Singleton, Type Wars, TDD Doesn't Work, TDD Harms Architecture, and roughly 90 others (including essays on hiring, certification, industry culture, and a handful of politically-themed posts).

The remaining ~40 Google Sites top-level articles — again, titles captured with some inline excerpts, bodies not individually fetched due to Google Sites' nav-heavy rendering (each fetch costs ~20K tokens in nav alone before the article body begins).

## Not fetched

- butunclebob.com front page and the full wiki structure beyond the few articles surfaced via web_search. The old wiki is largely dormant; the direct URLs I tried returned empty pages; content was reachable only via search result excerpts.
- cleancoders.com video-episode descriptions (peripheral; the book/blog material covers the same ground).
- Uncle Bob's Twitter/X archive (referenced in a few places but I fetched only material that appeared in search results).

## What this means for the skill

- Core-principle claims (the SOLID wording, the Clean Architecture layers, the TDD three laws, the F.I.R.S.T. attributes, the test taxonomy, the Data/Object Anti-Symmetry, the three paradigms, the oath) are backed by directly fetched body text or search-excerpt evidence.
- Some narrower historical and biographical claims (the Parnas 1972 citation, Liskov 1987 date, Meyer 1988 OOSC citation, attribution of specific phrasings to specific articles) were corroborated across multiple sources but not verified at their original citations. If any of them matters for a formal use, double-check against the original paper.
- The sections on ~120 unfetched blog posts are not directly represented in the skill — the skill is built from the ~25 sources I did read fully, plus the consistent pattern of excerpts from the rest.

If there's a specific blog post from the unfetched list that you want me to integrate, point me at it and I'll fetch it directly and revise the relevant reference file.
