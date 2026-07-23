# Handoff — Closed beta: 3-day data read + product-strategy discussion

## Where the work lives (current session — 2026-07-23)
- **No code changes this session.** This was a data-analysis + product-strategy session; the only file written
  is this `HANDOFF.md`. Nothing to deploy.
- Branch/deploy unchanged from the instrumentation session: `origin/main` holds the four instrumentation commits
  (`680cda5` → `1b10715`). Local `main` in the primary checkout is still behind — `git pull` there next session.
  Edits were made in worktree `.claude/worktrees/events-instrumentation` and pushed to `origin/main`.
- **The `events` table now holds REAL beta data — do NOT wipe it.** (Last session it was reset to 0 for a clean
  window; as of this read it has ~42 real rows from 7 users. Leave it alone.)

## The data after 3 days (read 2026-07-23; ~20 invited users)
Raw pull from the `events` table via the SQL editor (service role). n is tiny — directional only, ~2 actual
data-days. Coaching intuition outranks these numbers at this n.
- **42 events, 7 distinct users of ~20** → ~13 invited users never opened the board at all (no `session_start`).
- **3 of the 7 fired only `session_start`** — opened and bounced → **~4 genuinely active users.**
- **Q1 (multi-step?):** Yes but shallow. 4 users added a 2nd frame; only 2 reached 3 frames; **max depth = 3.**
- **Q2 (Play?):** Yes — the hero feature. 3 users, 7 `playback_start`. One user hit `playback_blocked` 3×
  (pressed Play on a single frame — wanted animation, didn't know to add a step first).
- **Q3 (export?):** **Zero.** No `export_png`/`export_shared` from anyone.
- **Q4 (tour drop-off?):** None — it completes. 3 users hit steps 1→2→3, ended mostly `finished`, one `skipped`,
  **zero `backdrop`.** The Batch-E "stray tap kills onboarding" suspicion is NOT appearing.
- **Q5 (return?):** No day-2 returns yet (every user `active_days=1`); only one possible return day → inconclusive.
- **Dead events across the board:** `scenario_save`, `scenario_load`, `scenario_delete`, `export_png`,
  `lang_switch`, `frame_delete` — all zero.
- **Cross-check:** the `scenarios` table has NOT grown since launch (most recent save 07-21, pre-launch), so
  "nobody saves" is real behaviour, not an instrumentation gap — which also validates the instrumentation.
- **Platform/lang:** ~63% desktop sessions, **100% Thai, zero `lang_switch`** — the EN path is unused so far.

## Product-strategy analysis (to discuss next session)
Coach's own read, all supported by the data: (a) useful but not an everyday tool; (b) a link is harder to use
than a real app; (c) some coaches use it to *look* professional rather than to *be* professional; (d) only 2–3
of 20 gave verbal feedback despite being asked.

**Central thesis — the tool is hired for a different job than it was built for.**
- *Used* features (build shallow multi-step → Play) belong to a **"communicate a play right now"** paradigm.
- *Dead* features (save / load / tags / export / language) belong to a **"maintain a durable playbook"** paradigm.
- It was built as the second; it's used as the first. This one mismatch explains nearly every finding. The one
  genuinely differentiated capability — **animated multi-step playback** — is exactly what users found on their own.

**Fundamental design critique.** The entire persistence layer (per-team saved scenarios, RLS isolation, load
manager, tags, PNG export) assumes a shared team playbook nobody is building — over-built relative to demand.
Actual use is presentational and ephemeral: assemble a quick animated play, show it live (likely screen-shared in
a team talk / Line call), move on. Static PNG export throws away the animation — probably *why* export is dead:
it exports the wrong artifact.

**The three coach reads, sharpened:**
1. *Not everyday* → correct; it's an **episodic** tool. Stop chasing DAU; aim to be "the default tool at the
   moment of need." Metric = used-per-prep-session, not daily.
2. *Link ≠ app* → real, and the cheapest high-leverage fix. A link wins trial but loses retention (no home-screen
   presence, not where coaches live: Line / Discord / in-game). A **PWA** (installable, offline, native-feeling)
   resolves it; the single-file build is well-positioned for it. Distribution problem, not a feature gap.
3. *Look pro vs be pro* → **flip it into the strategy.** Vanity is a legitimate growth engine. The problem is the
   pro-looking moment **never leaves the app** (0 exports) → zero word-of-mouth. **The referral loop is broken at
   the export step.**

**Highest-leverage single change (hypothesis):** replace static PNG export with a **one-tap, branded, animated
share** (looping GIF / short clip of the playback) pushed to Line. It (a) serves the real job, (b) closes the
referral loop — a slick animated rotation in a team chat gets seen by players / other coaches → "what tool made
that?" — and (c) converts vanity into distribution. A subtle "made with [board]" mark makes every share a
marketing surface. Target loop: build → play → **share something worth posting** → someone asks → new coach.

**Sequencing discipline (important):** only ~4 active users. Do NOT build a growth/virality engine on a leaky
bucket. Order: (1) **understand the people** — talk to the 4 active users AND, more importantly, the ~13 who
never opened it (invisible in the data, the most valuable interviews); (2) make build→play→share undeniable for
the few; (3) THEN open the referral loop / PWA / growth.

**Feedback method fix (the 2–3 responders problem):** broadcast "feedback is valued" selects for nobody. Instead:
(a) go 1:1 with behaviorally-specific questions the data now enables ("I saw you built a 3-step play and hit Play
twice — did you show your team? what stopped you saving it?"); (b) interview the non-openers; (c) add ONE
in-context 👍/👎 right after playback; (d) weight behavior over words — the instrument is already built, trust it
over the quiet inbox.

**Tension to resolve next session:** this argues AGAINST the original plan's "wait two weeks, then rank the
Batch E backlog." **Batch E is polish on a product whose core loop isn't proven.** If this framing holds, the
next step is conversations + a possible pivot toward the communicate/share job — not the Batch E commits.

## Next steps (for the discussion session)
1. **Decide the framing** (this gates everything else): is the job "communicate a play fast" (lean in: playback +
   animated branded share + PWA) or "team playbook" (fix discoverability of save/load)? The data leans hard toward
   the former.
2. **Talk to people before building:** 2–3 active users + 2–3 non-openers, with the specific questions above.
   Highest-value action, zero code.
3. **If framing = communicate/share:** scope the animated-share-to-Line export + a subtle brand mark, and the PWA
   install — these attack link≠app and the broken referral loop directly.
4. **Re-decide Batch E:** likely defer/deprioritize vs the core-loop work above. One micro-item worth keeping: the
   `playback_blocked` user (Play with 1 frame gives a toast but no path forward) — a real onboarding gap, n=1.
5. **Reframe the north-star metric:** "did a coach share a play?" as the leading indicator of both value and growth.

## Open questions / decisions pending
- Communicate-job vs playbook-job framing (next-step 1) — the pivot decision.
- Invest in PWA + animated share now, or wait for more users first?
- Keep waiting the original two weeks for more data, or act on 1:1 conversations sooner? (The analysis says
  conversations > more low-n data right now.)

---

## Previous session — behavioural instrumentation (events_v1)

## Where the work lives (instrumentation session)
- Branch: `main` (this project commits directly to main; no PR workflow). This session's edits were made in a
  git worktree (`.claude/worktrees/events-instrumentation`) because the background-job harness enforces
  isolation, then pushed straight to `origin/main` with `git push origin HEAD:main` so GitHub Pages still
  deploys from main. **Local `main` in the primary checkout is therefore behind `origin/main`** — fast-forward
  it with `git -C /Users/cr/sucrose-tactic fetch && git -C /Users/cr/sucrose-tactic merge --ff-only origin/main`
  (or just `git pull`) at the start of next session.
- Pushed: yes, three commits, each verified live before the next:
  - `680cda5` — Instrumentation 1/3: `events_v1` migration appended to `supabase-beta.sql`.
  - `b5f524e` — Instrumentation 2/3: `track()`/`flushEvents()` helper + `session_start`.
  - `f22b9c8` — Instrumentation 3/3: the remaining 13 event call sites.
- Deploy: GitHub Pages, live at https://cakrintnchnachay-commits.github.io/sucrose-tactic/
  Each SHA confirmed **built** via the Pages Builds API (not just queued), then behaviour verified in a real
  signed-in browser against the live HTTPS site — see the Instrumentation verification list below.

## Instrumentation — events_v1 analytics (this session)
Implemented `INSTRUMENTATION-PLAN.md` verbatim: a write-only `events` table + a batched client `track()` helper
+ 14 event call sites, scoped to answer exactly five questions (multi-step plays? Play? export? tour drop-off?
retention?). Nothing beyond the 14 events in the plan was added.

**Schema (`supabase-beta.sql`, migration `events_v1`, applied to remote `nauthibrxazwiywosmjz`):** `events`
table with `user_id` (not null, FK auth.users), `org_id` (nullable, FK orgs on-delete-set-null), `name`,
`props jsonb`, `session_id`, `ts`. RLS **enabled**, one **insert-self-only** policy
(`with check user_id = auth.uid()`), and **no select policy by design** — the browser cannot read the table
back; you read it from the SQL editor (service role). Three indexes (ts, name+ts, user+ts). The §4 read
queries in `INSTRUMENTATION-PLAN.md` are the intended way to look at the data.

**Client (`board.html`):** `track()`/`flushEvents()` helper placed right after the `ME` declaration. It is
fully self-wrapping (every failure swallowed) and batched (flush at 10 events, on a 5s timer, or on tab-hide
via `visibilitychange`) so it can never throw into or block a user action, and one insert never lands inside a
drag gesture. **PII rule honoured: props are counts/enums/bools only** — no scenario name, no `#notesBox` text
(only a `has_notes` boolean), no display name, no email. All 14 sites are hooked to **user-facing handlers, not
state functions** — the two documented traps (`frame_add` on `addFrame` not `applyBoardState`'s rebuild;
`playback_start` on `togglePlay` not the per-frame `setFrame`) are both avoided. `tourSkip(how)` gained a
`how` arg so a backdrop-tap (`'backdrop'`) is distinguishable from skip/finish — this measures the
Batch-E "stray tap kills onboarding" suspicion before deciding whether to fix it.

**`tokens` prop interpretation:** `scenario_save.tokens` = current-frame hero count (`F().heroes.length`). The
plan left `tokens` undefined; this is the chosen meaning — note it when reading the data.

**Verified live (signed-in, against the deployed site):**
- Migration: under the publishable key, `select` on `events` → 0 rows (RLS working), `insert` → 201; probe row
  landed with correct `user_id`/`org_id`; the `!ME.orgId` path stores `org_id` **null**, not a crash.
- 12 of 14 event types exercised through the real deployed handlers and confirmed to land with correct props,
  correct `user_id`/`org_id`, and zero PII: `session_start`, `frame_add` (total increments), `playback_start`,
  `playback_blocked`, `export_png`, `lang_switch`, `tour_step`, `tour_end` (incl. `how:'backdrop'`),
  `scenario_save` (both `overwrite:false` insert and `overwrite:true` overwrite), `scenario_load` (`age_days`),
  `scenario_delete`. Batch-at-10 auto-flush also confirmed.
- The 3 not live-exercised are **code-reviewed + syntax-checked only**, not clicked: `frame_delete` (identical
  pattern to the verified `frame_add`), `export_shared` (needs a real native share sheet), `scenario_save_failed`
  (needs a forced offline / RLS-reject state).
- **All developer-test rows were deleted afterward — the `events` table is currently empty (0 rows)** so the
  two-week measurement window starts from a clean slate.

**Still to do by you (out of scope for this exercise on purpose):**
- Tell the 10 beta users, one line: "the beta records which buttons get used, never your plays or notes"
  (`INSTRUMENTATION-PLAN.md` §5). This makes the PII rule enforceable and is the difference between
  instrumentation and surveillance.
- **Wait two weeks, then read the §4 queries.** Do NOT rank/start the Batch E backlog before then — the wait
  is the entire point.

---

## Prior session — Closed beta pre-launch audit + fixes (Batches A–D)

## Where the work lives (prior session)
- Branch: `main` (this project commits directly to main; no PR workflow in use).
- Pushed: yes. Commit `f0b03cc` — "Phase 8: Thai translation fixes + release polish (Batch C+D beta audit)".
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
- ~~**NOT done**: no click-through of Save/Load/Delete/Export-PNG button interactions in a real browser.~~
  **Now DONE (instrumentation session).** While verifying the `scenario_save`/`load`/`delete`/`export_png`
  events live, the real deployed handlers were exercised end-to-end against the live HTTPS site by stubbing
  `window.confirm` (auto-accept, so the native dialogs don't freeze automation) and stubbing `downloadCanvas`
  (so Export doesn't trigger a real file download): a `__instr_test__` scenario was saved (insert), saved
  again (overwrite-confirm), loaded (over the dirty-changes discard-confirm), and deleted (delete-confirm), all
  succeeding, and the test scenario was removed afterward. Export PNG ran through `exportPNG()` cleanly. The one
  gap that remains code-review-only is the **visual** Export-PNG ward-range-ring check (the `vision.r.ward`
  Batch-A fix) — the render path ran without error but the exported image was not eyeballed, since the download
  was stubbed to avoid writing a file.

## Next steps, in priority order
1. **Wait two weeks, then read the `INSTRUMENTATION-PLAN.md` §4 queries** against the `events` table (SQL
   editor). Do not rank or start Batch E before then — the wait is the point of the instrumentation exercise.
   Also send the beta users the one-line "we record button usage, never your plays/notes" note (§5).
2. Batch E (backlog above) whenever you want to pick it up — none of it is urgent for a closed beta with a
   small, forgiving audience. `tour_end.how = 'backdrop'` counts will tell you whether the stray-tap-kills-
   onboarding item is actually worth fixing.
3. The `members_update_self` RLS tightening — needs a Supabase migration, doable via the Supabase MCP tools
   whenever convenient, not urgent since the gap is currently inert.
4. (Optional) Visually eyeball an Export-PNG ward-range ring once by hand — the only Batch-A/B item still
   verified by code-review rather than a real rendered image (see the Verification note above).

## Open questions for you
- None blocking. Everything scoped from the original 5-agent audit (Batches A–D) is now shipped and verified
  live. Batch E and the RLS migration are optional backlog whenever you want them.
