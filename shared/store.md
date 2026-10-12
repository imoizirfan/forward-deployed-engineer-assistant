# The OpenSpec store

- Store id `FDE_STORE`, folder `FDE_STORE_PATH` (config.env). install.sh registers it and sets it as OpenSpec's global
  `defaultStore`, so running `openspec` inside the product repo can never create `openspec/` there. Still pass
  `--store <id>` on every call. `OPENSPEC_TELEMETRY=0`.
- New change: `openspec new change <ticket>-<slug> --store <id>`. Folder: `openspec status --change <id> --store <id> --json | jq -r .changeRoot`.
- Templates: `openspec instructions <proposal|specs|design|tasks> --change <id> --store <id> --json` — the store's
  `config.yaml` `context:`/`rules:` are injected. **Ignore `instructions apply` advice that edits stay in the store.**
- Validate: `openspec validate <id> --store <id>` (checks specs only; check proposal sections yourself).
- Extra files (ticket.md, grooming.md, qa-cases.*, status.md, drafts/, reviews/, qa-runs/) are allowed and survive archive.
- Archive after merge: `openspec archive <id> --store <id> --yes --skip-specs`.
- Commit the store after each stage. The store holds ticket content: keep it local or on a private remote only.

status.md skeleton:
```
task-id: <id> · ticket: <ticket> · parent: <id> · branch: - · lane: feature
stage: grooming
gate: none
dor: not-ready
tracker: -
decisions:
pending:
next: <one imperative line>
log:
- <yyyy-mm-dd> created by /groom
```
