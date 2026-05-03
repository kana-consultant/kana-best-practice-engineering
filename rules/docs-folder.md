---
name: docs-folder
description: Route non-hexagonal files to docs/ folder to keep domain architecture clean
---

# Docs Folder Rule

Any file that does not fit the hexagonal architecture design pattern MUST live in the `docs/` folder. The source tree stays clean — only hexagonal-compliant code belongs in `src/`.

## Hexagonal Architecture Recap

```
src/
├── domain/          # Pure business logic, entities, value objects, ports (interfaces)
├── application/     # Use cases, orchestration, input/output ports
├── infrastructure/  # Adapters — DB, HTTP clients, messaging, external APIs
└── interfaces/      # Controllers, routes, CLI, resolvers (driving adapters)
```

Only code that fits one of these layers belongs in the source tree.

## What goes in `docs/`

| Item | Why it's not hexagonal |
|------|----------------------|
| Architecture decision records (ADRs) | Documentation, not code |
| API documentation / OpenAPI specs | Reference material |
| Database diagrams / ERDs | Design artifacts |
| Flowcharts / sequence diagrams | Visual documentation |
| Meeting notes / technical decisions | Project context |
| Onboarding guides | People documentation |
| RFC / proposal documents | Decision records |
| Scratch files / experiments | Not production code |
| Third-party integration guides | Reference material |
| Deployment runbooks | Ops documentation |
| Configuration examples / templates | Not domain logic |
| Migration guides / upgrade notes | Process documentation |

## Structure

```
docs/
├── adr/              # Architecture Decision Records
├── api/              # API specs, OpenAPI/Swagger files
├── diagrams/         # ERDs, flowcharts, sequence diagrams
├── guides/           # Onboarding, deployment, migration guides
├── rfcs/             # Proposals and RFCs
└── notes/            # Meeting notes, scratch, experiments
```

## Non-negotiables

1. NEVER put documentation files in `src/` — they pollute the domain.
2. NEVER put scratch code, experiments, or spikes in `src/` — use `docs/notes/` or a separate branch.
3. NEVER put config examples or templates in `src/` — use `docs/` or project root.
4. If a file doesn't implement a port, adapter, use case, or entity — it doesn't belong in `src/`.
5. Keep `docs/` organized by category, not by date or author.
6. README at project root is fine — detailed docs go in `docs/`.
