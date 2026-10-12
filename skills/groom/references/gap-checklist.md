# Grooming gap checklist (product-facing)

For each dimension ask: does the ticket answer it? does the code contradict it? would QA or another platform interpret it
differently? Only record a gap with evidence and an "effect if ignored".

**Scope edges**
- Claims like "across the app / everywhere / all screens" vs the screens actually listed → ask for the list or an explicit out-of-scope.
- Attachments that imply extra work (fonts, assets, copy decks) — in scope? size cost? who provides?
- Is the ticket status already past grooming (work started)? Say so.

**Variants (brands / tenants / regions)**
- Variant fields vs title ("ALL") — which wins?
- Which variants actually reach the touched code (code branches, per-variant folders, per-variant config defaults)?
- Variants with different languages or OS floors (see `profile.variants`) — confirm from code, not habit.

**Languages, RTL, numerals**
- en and ar copy both given? Who owns translation? Digit system (Western vs Eastern Arabic) and separators.
- RTL ordering of ranges/units ("A - B" reads reversed in RTL), currency symbol placement, mixed-direction strings.
- Multiple candidate copies in the ticket (e.g. "Alternate" columns) — which one ships?

**Data source**
- Where does the displayed content come from: hardcoded, localized catalog, remote config (key + shipped default per
  variant), API field (backend owns it)? If remote config/API, the fix may be a data change, not a release.
- Is the ticket's "Remote Config" field consistent with what the code reads?

**States**: loading · empty · error · offline · long text/large numbers · first launch · guest/logged-out.

**Design**: link present? all states designed? "Design not required" — then who signs off visuals?

**Analytics**: event name, trigger moment, params, dedupe, which SDKs; or an explicit "none". Existing events whose
params would change (e.g. a displayed label sent as a param) count.

**Rollout**: remote-config kill switch / gradual rollout needed? Backward compatibility with older app versions
reading the same config.

**Backend contract**: endpoint exists (Router case)? fields exist? who changes them? other platforms use the same contract?

**Deep links / push** that land on the screen. **UI test identifiers** needed for e2e on new/changed elements.

**Platform parity**: sibling tickets (other platforms) exist? same scope? same copy?

**Success metric & dependencies**: how will PO know it worked; anything blocking (other tickets, releases, design).

**Acceptance data quality**: typos, inconsistent rows, missing words in tables the ticket provides (they become bugs verbatim).
