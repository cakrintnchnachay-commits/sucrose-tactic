# Handoff — Closed beta pre-launch audit + fixes

## Where the work lives
- Branch: `main` (this project commits directly to main; no PR workflow in use).
- Pushed: yes. Latest commit `f0b03cc` — "Phase 8: Thai translation fixes + release polish (Batch C+D beta audit)".
- Deploy: GitHub Pages, live at https://cakrintnchnachay-commits.github.io/sucrose-tactic/
  Build for `f0b03cc` confirmed **built** via the Pages API (not just queued), and then verified with a real
  browser load against the live HTTPS site (not just curl/grep) — see Verification section below.

## Files touched this session
- `/Users/cr/sucrose-tactic/board.html` — all Batch A/B/C fixes.
- `/Users/cr/sucrose-tactic/index.html` — meta/og tags, favicon link, SRI-pinned script, one Thai wording fix.
- `/Users/cr/sucrose-tactic/favicon.ico` — new. Accent-green target/crosshair, generated with Pillow, matches
  the vision-mode motif. 16/32/48px multi-size ICO.
- `/Users/cr/sucrose-tactic/assets/tactic-map.webp` — new. Replaces `tactic-map.png`.
- `/Users/cr/sucrose-tactic/assets/tactic-map.png` — deleted (superseded by the .webp above).
- `/Users/cr/sucrose-tactic/HANDOFF.md` — this file.

## What happened this session
Ran a 5-agent audit (translation, usability, security, code correctness, release readiness) across
`index.html`, `board.html`, `supabase-beta.sql` ahead of the closed beta. Full findings are in the
conversation transcript, not re-filed elsewhere — re-run the same 5-way audit if this file goes stale and you
need the original detailed write-ups again.

**Batches A, B, C, and D were all implemented, verified, committed, and shipped this session**, across two
pushes (`622ee5b` then `f0b03cc`). Batch E (backlog) was scoped but intentionally not started — see below.

### Batch A — ship-blockers (commit `622ee5b`, DONE, verified live)
1. `exportPNG()` referenced an undefined `WARD_RANGE_W`, crashing PNG export whenever a ward's vision range
   was on (the default). Fixed to `vision.r.ward` — confirmed this matches the exact unit/scale convention
   the live board already uses in `visionCircleSVG`/`wardRangeSVG`.
2. Removed the dangling `<link rel="stylesheet" href="nav.css">` (file doesn't exist, 404'd every load).
3. Fixed a Thai plural bug: an English `{s}` placeholder was leaking literally into two Thai toast strings.

### Batch B — data-safety (commit `622ee5b`, DONE, code-traced + syntax-checked)
4. Save button disables + relabels "Saving…" during the async save (guards double-click double-submit).
5. Save-overwrite is now an **active confirm**, not just a static note.
6. Overwrite-detection query scoped by `.eq('org_id', ME.orgId)` in the client (defense in depth).
7. Offline-save fallback returns true/false; a real localStorage-quota failure now surfaces an error toast
   instead of a false "saved" message.
8. Loading a scenario over unsaved changes now confirms first (`dirty` flag check).
9. Deleting a scenario checks the Supabase response for an error before removing the card from the UI.
10. Restoring an offline save no longer wipes the local cache until a real online Save succeeds for that
    scenario name (`clearOfflineSavesByName`) — intentional behavior change, cache used to vanish the instant
    you clicked Restore even if you closed the tab before re-saving.

### Batch C — Thai/EN translation fixes (commit `f0b03cc`, DONE, verified live in a real browser)
- Fixed untranslated interpolations: the "switch to" menu item showed raw English "RED"/"BLUE" in Thai mode;
  ward labels were composed in the wrong Thai word order ("น้ำเงิน วอร์ด" instead of "วอร์ดน้ำเงิน"). Added
  `sideLabel()`/`wardLabel()` helper functions used at every call site instead of ad-hoc string concatenation.
- `relTime()` ("5m ago" etc. on every Load-modal card) and the Load-modal step count were English-only
  regardless of language — both now routed through new i18n keys (`time-just-now`, `time-mins-ago`,
  `time-hours-ago`, `time-days-ago`, `time-months-ago`, `step-count`).
- Fixed hardcoded English: the "Delete" button on the shape-selection pill, the hero-grid load/error
  messages (`heroes-supabase-not-loaded`, `heroes-load-failed`), and the vision-sync status text.
- The "All" position tab was untranslated; now uses a `data-pos` attribute to hold the stable filter value
  ('All') separately from the translated display label, so the click handler and active-state comparison
  don't break when the visible text changes between languages.
- Language toggle didn't retranslate the hero grid — `renderHeroGrid()` is now called from `setLang()`
  specifically (not from the general `renderAll()`, to avoid rebuilding the ~128-hero grid on every frame
  switch / playback tick — that was a deliberate scope-narrowing after an advisor review flagged the broader
  placement as unnecessarily expensive).
- **Honest-copy fix**: the vision-range setting's UI label and two code comments claimed "synced to all
  devices" / "synced across devices (Supabase)". No such sync exists — `scheduleVisionSync()` only ever
  writes to `localStorage`. Copy and comments now say "saved on this device", matching what the code actually
  does. (There's already a separate, accurate comment nearby noting real cloud sync is deferred to a future
  phase — this fix just makes the user-facing copy stop overpromising in the meantime.)
- Thai glyph rendering: extended the `:root[lang=th]` letter-spacing reset to cover labels that were missing
  from it (`.fs-label`, `.mini-pop .ph`, `.input-label`, `#ctxBar .lab`, `.section-label .sub`), and added an
  `IBM Plex Sans Thai` fallback ahead of `DM Mono` for `.mini-pop .ph`, `.tour-card`, `.toast` (DM Mono has no
  Thai glyphs, so those elements were silently falling back to the system monospace font for Thai text).
- `<html lang="en">` corrected to `lang="th"` (the actual default language, `LANG` variable already defaulted
  to `'th'`).
- Terminology consistency pass: ตัวละคร → ฮีโร่ (was inconsistent with the rest of the UI, reads like RPG
  talk rather than MOBA), eraser tool ลบ → ยางลบ (was colliding with Delete/Remove, all three said "ลบ"),
  ป้อมปราการ → ป้อม (`towers` key now matches the singular `tower` key), duplicate-step ทำซ้ำ → คัดลอก (was
  colliding with Redo's ทำซ้ำ — two different actions, one Thai verb), vision toggle labels (มองเห็น → วิชั่น,
  the standard Thai esports transliteration), sign-in copy register unified with index.html's เข้าสู่ระบบ
  family, and tour copy that referenced English button names ("Move", "Save", "Load") now references the
  buttons' actual Thai labels ("ย้าย", "เซฟ", "โหลด").

### Batch D — release polish (commit `f0b03cc`, DONE, verified live)
- `assets/tactic-map.png` (1.9MB) recompressed to `assets/tactic-map.webp` (248KB, 87% smaller) at WebP q90.
  Visually verified before committing (rendered the file and inspected it) — no visible artifacts at this
  map's detail level. The old `.png` was deleted; only reference to it (`board.html`'s `#mapImg`) updated to
  the new filename. Confirmed on the live site: old PNG now 404s, new WebP serves 200 at full 2023×1080.
- Added a favicon (`favicon.ico`, generated with Pillow — concentric-ring "target/crosshair" in the app's
  accent green on its dark background, echoing the vision-mode ward-range rings). None existed before;
  GitHub Pages was serving no tab icon.
- Added `<meta name="description">` and `og:title`/`og:description`/`og:image`/`og:url` +
  `twitter:card` to `index.html`, so the beta invite link previews properly when shared in Line/Facebook/etc.
- Pinned the Supabase CDN script (both pages) from the floating `@2` alias to the exact resolved version
  (`@2.110.7`) and added an SRI `integrity` hash + `crossorigin="anonymous"`, closing a supply-chain gap (an
  unpinned, unverified CDN script previously had full access to the page and the user's Supabase session).
  **Verified in a real browser against the live HTTPS site** that the pinned+hashed script still loads
  correctly and `window.supabase.createClient` is available — this was the one change in this batch that
  could have silently broken all of auth/save/load if the SRI hash were wrong (a bad hash makes the browser
  block the script entirely with no fallback), so it was checked live, not just by parsing.
- **Intentionally did NOT add `defer`** to the Supabase CDN script, despite that being in the original Batch D
  scope from the release-readiness audit. Both `index.html` and `board.html` call
  `window.supabase.createClient(...)` from a large non-deferred inline `<script>` later in the document body.
  That inline script runs synchronously the instant the parser reaches it — deferring only the CDN `<script>`
  tag would make it execute *after* that inline script instead of before, so `window.supabase` would be
  `undefined` when `createClient()` is called and `sb` would become `null` on every page load, silently
  breaking all auth/save/load. Fixing this properly would require also restructuring the inline init script
  (e.g. wrapping it in `DOMContentLoaded`), which is a real code-structure change, not a one-line perf tweak —
  left for a future session if the render-blocking cost of the CDN script actually becomes a problem in
  practice (it's a single small script, low priority).

### Batch E — post-beta backlog (NOT started, still pending)
- No logout control on the mobile/phone view (desktop-only `#btnLogout`).
- First-run tour: a single stray tap anywhere on the backdrop permanently dismisses onboarding.
- Deleting a step has no confirm and wipes undo history.
- Load modal has no loading state while fetching (`select('*')` pulls every scenario's full `board_state` +
  preview before showing anything).
- Touch targets below 44px in several places (notably the 16px bench-remove "×").
- Long-press-for-menu on step chips is cancelled by any 1px pointer jitter (no movement threshold, unlike
  `enablePieceDrag` elsewhere in the same file, which already uses a 6px threshold).
- Hero grid briefly shows "No heroes match." during the very first load before data arrives.
- A signed-in user who clicks an old/expired magic link is stranded on the error message instead of being
  redirected into the board they already have access to.

### Security items, not urgent but noted (from the security audit)
RLS and the two prior XSS/exec-lockdown fixes (preview_image escaping, `my_org_id()` lockdown) were both
verified correct this session — no new high-severity issues found. One item remains, needs a Supabase
migration (not a board.html change), not done this session:
- `members_update_self` RLS policy on `org_members` lets a member update their own `role` column via the raw
  REST API with no restriction. Inert today (nothing in the app currently reads/enforces `role` for
  authorization), but it's a self-escalation footgun the moment `role` is wired into any permission check.
  Recommended fix: add a `with check` that also pins `role` to its prior value, or move role changes behind a
  `security definer` RPC instead of a raw policy.

## Verification performed this session
- Syntax-checked the entire inline `<script>` block in both `board.html` and `index.html` with Node
  (`new Function(...)`) after every batch — clean both times.
- Checked the `STR` i18n table for duplicate keys programmatically (152 keys, zero duplicates) after Batch C.
- Manually traced the `vision.r.ward` fix (Batch A) against the existing `visionCircleSVG` code path to
  confirm matching units/scale, not just that it parses.
- Visually inspected the recompressed `tactic-map.webp` (Batch D) before committing — rendered it and checked
  for artifacts by eye, not just file size.
- Ran a local static server after each batch; confirmed all referenced assets resolve with no stray 404s
  (checked specifically for the removed `nav.css` and the old `tactic-map.png` — both correctly absent).
- After Batch C+D, an advisor review caught two things that plain syntax-checking couldn't: (1) the SRI hash
  needed a real browser load to verify, since a bad hash fails silently/catastrophically (browser blocks the
  script, `sb` becomes `null`, all auth/save/load dead, with only a console error as a clue); (2) the initial
  `git add board.html` habit from the Batch A/B commit would have missed the new webp/favicon/deleted-png in
  this larger batch. Both were corrected before shipping: staged all five changed files explicitly, and
  drove a real Chrome tab (via the claude-in-chrome tools) to the **live HTTPS site** post-deploy and
  confirmed `window.supabase.createClient` exists, the WebP map loads at full resolution, the "All" tab shows
  "ทั้งหมด", and `document.documentElement.lang === 'th'`.
- After push, polled the GitHub Pages Builds API until status was `"built"` for the exact pushed commit SHA
  (both `622ee5b` and `f0b03cc`), then fetched the **live** files over HTTPS and grepped/curled to confirm
  every specific fix landed (not just that the build succeeded) — the old PNG 404s live, the new WebP 200s
  live, the pinned Supabase URL and SRI hash are present, etc.
- One console warning ("heroes load failed") appeared on the very first live page load; re-tested with a
  fresh reload and it did not reproduce, and a manual re-run of the same Supabase query returned 128 heroes
  with no error — concluded to be a one-time cold-start race unrelated to anything changed this session, not
  a regression. Worth a mental note if it ever recurs, but not acted on.
- **NOT done**: no click-through of Save/Load/Delete/Export-PNG button interactions in a real browser. Those
  two `confirm()` dialogs (load-over-unsaved, overwrite-scenario) added in Batch B are native JS dialogs that
  would freeze Chrome-extension-driven automation if clicked into — verification for Batch A/B was code-trace
  + syntax-check only, not a live click-through. This remains the single highest-value manual test left before
  a real demo: place a ward with vision range on, Export PNG and visually confirm the ring size; then
  exercise Save (try a double-click), Save-with-an-existing-name (confirm the overwrite prompt appears and
  says the right thing), Load-over-unsaved-changes (confirm the discard prompt appears), and Delete.

## Next steps, in priority order
1. **Manual click-test Save/Load/Delete/Export-PNG once in a real browser** (by hand, or ask me to drive it —
   I'd need you to click through the two `confirm()` dialogs yourself if I use the Chrome extension, since
   they'll block automation). This is the one thing in Batches A/B that's verified by code-reading and
   syntax-checking but not by actually clicking the buttons.
2. Batch E (backlog above) whenever you want to pick it up — none of it is urgent for a closed beta with a
   small, forgiving audience.
3. The `members_update_self` RLS tightening — needs a Supabase migration, doable via the Supabase MCP tools
   whenever convenient, not urgent since the gap is currently inert.

## Open questions for you
- None blocking. Everything scoped from the original 5-agent audit (Batches A–D) is now shipped and verified
  live. Batch E and the RLS migration are optional backlog whenever you want them.
