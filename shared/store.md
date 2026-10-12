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
size: -
tracker: -
decisions:
pending:
waiting:
next: <one imperative line>
log:
- <yyyy-mm-dd> created by /groom
```

Fields:
- `lane`: `small | feature | bug`.
- `stage`: `intake | diagnosing | grooming | ready | building | reviewing | done | released | blocked`.
- `size`: the estimate given by /scope or /groom, as `S|M|L|XL (<days>)`. /retro compares it with the actual.
- `waiting`: one line per external dependency, `- <who> · <what> · since <yyyy-mm-dd>`. A skill adds the line when
  it asks someone for something (a posted question, a backend contract, a design) and deletes it when answered.
  /fde reads these lines to show who you are blocked on and for how long.
- Fields may share the first line separated by ` · ` (as above) or sit on their own lines; scripts accept both.

Store-level files (outside change folders), written by /retro and read by /scope:
`calibration.tsv` (estimate vs actual per change), `decisions.md` (product decisions by capability),
`platform-feedback.md` (friction worth raising with the platform team).
