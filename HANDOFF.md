# Handoff — Closed beta pre-launch audit + fixes

## Where the work lives
- Branch: `main` (this project commits directly to main; no PR workflow in use).
- Pushed: yes. Latest commit `622ee5b` — "Phase 7: fix PNG export crash + data-safety gaps (Batch A+B beta audit)".
- Deploy: GitHub Pages, live at https://cakrintnchnachay-commits.github.io/sucrose-tactic/
  Build for `622ee5b` confirmed **built** (not just queued) via the Pages API, and the live `board.html` was
  fetched and diffed to confirm the fix content is actually present (not just that the build succeeded).

## Files touched this session
- `/Users/cr/sucrose-tactic/board.html` — all Batch A+B fixes below.
- `/Users/cr/sucrose-tactic/HANDOFF.md` — this file (new).
No other files were created or moved.

## What happened this session
Ran a 5-agent audit (translation, usability, security, code correctness, release readiness) across
`index.html`, `board.html`, `supabase-beta.sql` ahead of tonight's closed beta. Full findings are in the
conversation transcript, not re-filed elsewhere — re-run the same 5-way audit if this file is stale and you
need the original detailed write-ups again.

**Batch A + B were implemented, verified, committed, and shipped this session.** Batches C/D/E (below) were
identified but NOT started.

### Batch A — ship-blockers (DONE, verified live)
1. `exportPNG()` referenced an undefined `WARD_RANGE_W`, crashing PNG export whenever a ward's vision range
   was on (the default). Fixed to `vision.r.ward` — confirmed this matches the exact unit/scale convention
   the live board already uses in `visionCircleSVG`/`wardRangeSVG` (same `imgToWorld`→add radius in world
   units→`worldToImg` pattern), so it's not just syntactically valid, it renders at the correct scale.
2. Removed the dangling `<link rel="stylesheet" href="nav.css">` — that file doesn't exist in the repo, so
   every board load 404'd on it.
3. Fixed a Thai plural bug: an English `{s}` placeholder was leaking literally into two Thai toast strings
   ("...3 สเต็ปs"). Thai has no plural; placeholder removed from the `th` strings only.

### Batch B — data-safety (DONE, verified via code trace + syntax check, NOT manually click-tested)
4. Save button now disables + relabels "Saving…" during the async save, guarding against a double-click
   producing two duplicate-named scenario rows.
5. Save-overwrite is now an **active confirm** (was previously just a static note in the modal) — shows
   "'X' already exists (last saved {when}). Overwrite it?" before updating an existing row.
6. The overwrite-detection query is now scoped by `.eq('org_id', ME.orgId)` in the client (defense in depth
   on top of RLS, in case two orgs ever pick an identical scenario name).
7. Offline-save fallback (`pushOfflineSave`) now returns true/false; if the localStorage write itself fails
   (quota full), the user gets a real error toast pointing at Export PNG, instead of a false "saved" message.
8. Loading a scenario over unsaved changes now confirms first (`dirty` flag check) instead of silently
   discarding work.
9. Deleting a scenario now checks the Supabase response for an error and toasts it, instead of removing the
   card from the UI even when the delete silently failed server-side.
10. Restoring an offline save no longer immediately wipes the local cache entry — it stays (and `dirty` is
    set true, so `beforeunload` will warn) until a real online Save succeeds for that scenario name
    (`clearOfflineSavesByName`). This is an intentional behavior change from before: previously the cache
    entry vanished the instant you clicked Restore, even if you closed the tab before re-saving.

New i18n keys added (both `en`/`th`): `offline-save-failed`, `confirm-load-over-unsaved`,
`confirm-overwrite-scenario`, `delete-failed`.

### NOT done — still pending from the audit

**Batch C — Thai/EN translation fixes** (biggest remaining user-visible issue set):
- "สลับไปฝั่งRED" / "น้ำเงิน วอร์ด" (wrong word order/untranslated interpolation) in ward/token menus.
- `relTime()` (board.html, "Xm ago"/"Xh ago" on every Load-modal card) is English-only, not routed through
  the i18n table at all.
- Load-modal step count ("3 steps"), the "Delete" button on selection pills, and the vision-sync status text
  are all hardcoded English.
- Language toggle doesn't retranslate the hero grid (`renderHeroGrid()` isn't called from `renderAll()`/
  `setLang()` — a "no heroes match" message or the Recent-section label can stay in the old language after
  switching until the next keystroke/click).
- Thai glyph rendering: several labels (`.fs-label`, `.mini-pop .ph`, `.tour-card`, `.input-label`, etc.) use
  `DM Mono` + letter-spacing that splits Thai tone marks — not covered by the existing `:root[lang=th]` reset.
- `<html lang="en">` should be `lang="th"` (default language is Thai).
- Terminology consistency pass: ตัวละคร→ฮีโร่, eraser tool ("ลบ")→ยางลบ, ป้อมปราการ→ป้อม, tour copy that
  references button names that don't match the actual Thai button labels.
- **Honest-copy fix** (found by the code-correctness agent, high priority): the vision-range Board-sheet
  label promises "synced to all devices," but the code only ever writes to `localStorage` — there is no
  Supabase sync for vision settings at all. Either wire it through Supabase, or change the copy to stop
  promising a feature that doesn't exist. This is a trust issue, not just a translation nit.

**Batch D — release polish**:
- Compress `assets/tactic-map.png` (currently 1.8 MB) — biggest single load-time cost on the site.
- Add a favicon (none exists — GitHub Pages currently serves the default/none).
- Add `<meta name="description">` and `og:title`/`og:description`/`og:image` tags so the beta link previews
  properly when shared in Line/Facebook.
- Add `defer` to the Supabase CDN `<script>` tag; pin the version (`@2` → an exact `@2.x.y`) and add an SRI
  hash — currently unpinned and un-verified.

**Batch E — post-beta backlog** (lower priority, not urgent for tonight):
- No logout control on the mobile/phone view (desktop-only `#btnLogout`).
- First-run tour: a single stray tap anywhere on the backdrop permanently dismisses onboarding
  (`tourSkip()` fires on background click, not just the Skip button).
- Deleting a step has no confirm and wipes undo history.
- Load modal has no loading state while fetching (`select('*')` pulls every scenario's full `board_state` +
  preview before showing anything) and doesn't feel snappy on venue Wi-Fi.
- Touch targets below 44px in several places (notably the 16px bench-remove "×", right next to a tap target).
- Long-press-for-menu on step chips is cancelled by any 1px pointer jitter (no movement threshold, unlike
  `enablePieceDrag` elsewhere in the same file, which already uses a 6px threshold).
- Hero grid shows "No heroes match." during the initial load (before data arrives), which reads as broken;
  errors are English-only with no retry button.
- A signed-in user who clicks an old/expired magic link is stranded on the error message instead of being
  redirected into the board they already have access to.

**Security items, not urgent but noted** (from the security audit — RLS and the two prior XSS/exec-lockdown
fixes were both verified correct, no new high-severity issues):
- No SRI on the Supabase CDN script (see Batch D above).
- `members_update_self` RLS policy on `org_members` lets a member update their own `role` column via the raw
  REST API with no restriction. It's inert today (nothing in the app currently reads/enforces `role` for
  authorization), but it's a self-escalation footgun the moment `role` is wired into any permission check.
  Recommended fix (needs a Supabase migration, not a board.html change): add a `with check` that also pins
  `role` to its prior value, or move role changes behind a `security definer` RPC instead of a raw policy.

## Verification performed this session
- Syntax-checked the entire inline `<script>` block in `board.html` with Node (`new Function(...)`) — clean.
- Manually traced the `vision.r.ward` fix against the existing `visionCircleSVG` code path to confirm matching
  units/scale, not just that it parses.
- Reviewed the full diff by eye before committing.
- Ran a local static server, confirmed `board.html` loads with no `nav.css` request and the fix strings are
  present in the served file.
- After push, polled the GitHub Pages Builds API until status was `"built"` for the exact pushed commit SHA,
  then fetched the **live** `board.html` over HTTPS and grepped it to confirm `WARD_RANGE_W` is gone,
  `vision.r.ward` is present, and the new i18n keys are live. This is real proof the deploy took, not just
  that the build succeeded.
- **NOT done**: no actual browser click-through of Save/Load/PNG-export on the live site. The two new
  `confirm()` dialogs (load-over-unsaved, overwrite-scenario) and the disabled-during-save button were only
  verified by reading the code, not by clicking them in a real browser. If you want that level of confidence
  before tonight's demo, that's the single highest-value next step.

## Next steps, in priority order
1. **Manual click-test the Save/Load flow once in a real browser** (or ask me to drive it via the Chrome
   extension) — place a ward with vision range on, Export PNG, confirm the ring renders at the right size;
   then exercise Save (double-click test), overwrite-an-existing-name, Load-over-unsaved-changes, and Delete.
   Note: those two new `confirm()` calls are native JS dialogs — if driving via `claude-in-chrome`, they will
   block the automation until dismissed by hand (already flagged during the session, not yet hit).
2. Decide on Batch C's vision-sync copy fix specifically — that's the one item in the backlog that's a
   trust/honesty issue rather than pure polish, worth doing even if the rest of Batch C waits.
3. Run Batch C (translation fixes) and Batch D (release polish) — both were scoped in detail during the
   audit; ask to pick them back up and I can execute from the descriptions above without re-auditing.
4. Optional: apply the `members_update_self` RLS tightening via a Supabase migration (needs you or me with
   Supabase MCP access — not a board.html change).
5. Batch E is backlog — fine to defer past tonight.

## Open questions for you
- Do you want the vision-range "synced to all devices" copy fixed tonight (quick, changes 1-2 strings), or
  do you actually want real Supabase sync for vision settings built (bigger, not a tonight-sized task)?
- Should I go ahead and run Batch C + D now, or do you want to manually smoke-test Batch A+B on the live
  site first before more changes land on top of it?
