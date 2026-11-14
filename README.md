# GBA Swap Check

Offline-first PWA for validating crew shift and duty swap requests against GBA roster rules.

**Live app:** https://ayshalau.github.io/gba-swap-check/
**Source:** https://github.com/ayshalau/gba-swap-check

## Features

The app opens on the **Roster Import** tab — upload the roster PDF first, then build the swap
request from it.

- **Swap Check** - build a swap request from crew members, each listing their duty days in the request. Runs the full rule set and returns an approve/reject verdict with itemized findings.
- **Roster Import** — upload a roster PDF and read it in the browser. Duty days are extracted as editable rows, then added to a swap request in one click. The file is never uploaded to a server.
- **Rules** - all 34 rules are grouped by their source policy section. Toggle any rule off, or edit its threshold. Settings persist locally.
- **Records** - every check is saved with its result and findings; filter by result, search, load back into the form, delete, or export to CSV.

## Roster import

The **Roster Import** tab takes a roster PDF. Everything is read locally in the
browser — nothing is sent to a server.

A duty can also be **typed in by hand**: press **Add Flight Duty** under the drop zone and the
Extracted Duty Days editor opens with an empty row — no PDF needed. Fill in the date, the duty
code, the sector, the times and the block hour, and it joins the roster preview, the tally and
the exports like any other row. **Clear** empties the whole editor again.

### PDF roster (recommended)

A text-based PDF (exported from Excel or another app) is read with pdf.js:

- The text and its position are pulled from every page.
- Text items are grouped into printed rows by their vertical position.
- The header row is found by matching column names.
- Every printed heading becomes a column, including ones the sheet does not use
  ("S NO", "REMARK"), so those still take up their slot. A heading repeated side by
  side — the GBA roster prints `STD STD` and `STA STA`, local time first and UTC
  second — is kept as its own column but ignored.
- The data is clustered by its left edges to work out where each column actually
  starts and ends. Headings are then aligned to those clusters by centre position
  with a sequence alignment, so a column with no data at all (an empty "SD")
  is skipped instead of pulling the columns after it one place to the left.
- Every cell is placed in the column it belongs in, so multi-word values ("HB 880",
  "HKG CTS") stay together.
- Page footers (`PRINTED BY`, `TOTAL BLOCK TIME`) and other text outside the table
  are ignored.

The GBA roster this is built for has these columns:

| S NO | DATE OF DUTY | TYPE OF DUTY | Flight No | STD | STD (UTC) | FROM | TO | STA | STA (UTC) | BLOCK | REMARK |
|---|---|---|---|---|---|---|---|---|---|---|---|

- The first `STD` / `STA` are local times and are the ones used. The second pair is
  UTC and is ignored.
- `TYPE OF DUTY` carries the duty code: `OP - (FA4)` for a flight, `STB - H04` for
  standby, `OTH - A` / `OTH - GD` for other duties, and `DO` / `AL` / `SL` for a day off or
  leave. The day off requested `DO-R` is read as a day off as well.
- `S NO` and `REMARK` are ignored.

If the PDF has no text layer (a scan), the reader says so — the PDF must contain
selectable text.

#### Column mapping

Both the PDF roster headings and the Excel sheet headings are recognised, and the
roster fields are filled from them like this:

| Roster field | PDF column | Excel column |
|---|---|---|
| Date | DATE OF DUTY | Date |
| Duty | Flight No (flight) or the code in TYPE OF DUTY (`STB - H04` → `H04`) | Duty |
| Sector | FROM + TO | Sector |
| Dep Time | STD (local) | Dep Time |
| Arr Time | STA (local) | Arr Time |
| Duty Start | *derived*: Dep Time − 65 min | Duty Start |
| Duty End | *derived*: Arr Time + 30 min | Duty End |
| Duty Period | *derived*: Duty Start to Duty End | Duty Period |
| Block Hour | BLOCK | Block Hour |

- The mapping is the rule, so it is applied even if the uploaded PDF happens to print its
  own Duty Start, Duty End or Duty Period. A printed value is used only when the row has no
  STD or STA to derive from (for example a ground duty with no flight times).
- Duty Period is the total time from Duty Start to Duty End. It is a local-time figure, the
  way the roster sheet prints it.
- Block Hour is read from the sheet. It is the time actually spent in the air, so it is
  **not** the clock difference between the departure and the arrival when the two stations sit
  in different time zones — see **Time zones** below.
- A Flight No is recognised by its shape (`HB702`, `HB 2352`) and is written with a space
  as the sheet shows (`HB 880`). A standby or other duty code (`H04`, `H14`, `A`, `GD`) is
  not a flight number.
- Standby (`STB - H04`) fills Duty Start from STD and Duty End from STA, with no Dep Time,
  Arr Time or Block Hour. `DO`, `AL` and `SL` leave every time blank. A standby is added to the swap
  request as a **Standby** duty, so the standby rules apply to it.
- A duty with no times at all — `DUTY`, `NDA` and `NB` — is added to the request as a
  **Duty**: it carries no sector, no duty start and no duty end, and its card shows the duty
  code on its own. The rules still count it as a duty day, but the time-based rules skip it
  because it has no times.
- The rest day `DO-R` (written `DOR` on some sheets) is a **day off requested** — it counts as a
  **Day Off**, exactly the same as `DO` and `AL`: it is added to the request as a **Day Off**,
  with no sector and no duty times, it counts towards the days off entitlement, it is not a
  duty day, and it can be swapped like any other day off. Only the roster sheet keeps the
  printed code `DO-R`, so the requested day off is still recognisable, and the tally counts it
  in its own `DO-R` column.
- The sick leave `SL` is a **day off** as well: it is added to the request as a **Day Off**, with
  no sector and no duty times, and it is not a duty day. Unlike `DO` and `DO-R` it **cannot be
  swapped** — see the rule *Sick Leave (SL) Cannot Be Swapped* — so its tick is locked and the
  card says "Sick leave - not swappable". The printed code `SL` is kept, and the tally counts
  it in its own `SL` column, which only appears when the roster holds a sick leave.
- A two-sector duty day is one duty: Duty Start on the first sector row, Duty End and the
  total Duty Period on the last row, with the duty cells in between left blank.
- Whatever headings the uploaded PDF uses, the imported roster is always shown in the
  **Excel format**. If the PDF does not print the weekday, Day is taken from the date.
  Day and SD carry no extra meaning in a swap check, so neither is shown in the
  **Extracted Duty Days** editor; both are still read from the PDF and kept in the data.
- Under the crew name field in the **Roster Preview** sits the tally of the uploaded roster: the
  duty days and the days off by code, for example *"15 duty day(s) · 8 DO · 0 DO-R · 7 AL"*. `DO`,
  the day off requested `DO-R` and `AL` are each counted on their own, so the numbers add up to
  the days on the roster. The sick leave `SL` is counted on its own as well, and its column only
  appears when the roster holds a sick leave — a roster without one carries no empty `SL` column.
  The tally is shown on a phone as well as on a desktop.

The **Extracted Duty Days** rows show Date, Duty, Sector, Duty Start, Dep Time, Arr Time,
Duty End, Duty Period and Block Hour. Times are entered as four digits (`0810`) and
are stored as `08:10`; changing a time recalculates the Duty Start, Duty End and Duty Period
it feeds.

#### Adding a flight duty

**Add Flight Duty** adds a blank flight to the **Extracted Duty Days** table, for a duty that
the PDF missed. Fill in the date, the flight number and the departure and arrival times, and
the rest follows the same mapping as an imported row:

- **Duty Start** = Dep Time − 65 min, **Duty End** = Arr Time + 30 min
- **Duty Period** = Duty Start to Duty End, **Block Hour** = Dep Time to Arr Time, with the
  clock difference between the two airports taken off

The weekday is filled in from the date, and the row moves into date order once the date is
picked, so it sits with the rest of the roster. Adding a second flight on a date already in
the roster makes a two-sector duty day, which is shown as one duty: Duty Start on the first
sector, Duty End and the total Duty Period on the last.

#### Time zones

The roster is based in Hong Kong, so **every station is GMT+8** unless it is one of these:

| Time zone | Airports |
|---|---|
| GMT+9 | `CTS` Sapporo, `FUK` Fukuoka, `KIX` Kansai, `OKA` Okinawa, `NRT` Narita, `SDJ` Sendai, `ROR` Koror (Palau) |
| GMT+7 | `BKK` Bangkok, `HKT` Phuket, `DAD` Da Nang, `PQC` Phu Quoc, `PKZ` Pakse, `SUB` Surabaya |
| GMT+5 | `MLE` Malé (Maldives) |

The times on a roster are **local times**, so the block hours of a flight are not simply the
clock difference between the departure and the arrival:

- Hong Kong to Japan (GMT+9): the flight is **an hour shorter** than the clock says.
  HB 880, `HKG CTS`, departs 09:15 and lands 15:00 — a clock difference of 5:45 and a block
  of **4:45**.
- Japan to Hong Kong: the flight is **an hour longer** than the clock says. HB 881, `CTS HKG`,
  departs 16:00 and lands 20:40 — a clock difference of 4:40 and a block of **5:40**.
- Hong Kong to Thailand, Vietnam, Laos or Indonesia (GMT+7): **an hour longer**. Hong Kong to
  the Maldives (GMT+5): **three hours longer**.

The app works this out from the sector — the first airport is where the flight leaves and the
last is where it lands — whenever it derives a block hour: a flight added by hand, a row whose
times are amended, or a duty card with no printed block hour. A **block hour printed by the
roster is never changed**; the zone-aware figure reproduces it exactly, which is how the rule
was checked against the sheet.

The **Duty Period** is a different figure: it is the time from Duty Start to Duty End as the
roster prints it, in local time, and it is left alone.

#### Amending a time by hand

Changing the **Dep Time** or the **Arr Time** of a row moves the fields that follow from it:

| Field | Follows |
|---|---|
| Duty End | Arr Time + 30 min |
| Duty Period | Duty Start to Duty End |
| Block Hour | Dep Time to Arr Time, less the clock difference between the two airports |

The **Duty Start** is the crew's report time and is left where it is, so amending a flight
time never moves it. The exception is a row added by hand with **Add Flight Duty**: its Duty
Start was worked out from the Dep Time, so it follows the Dep Time until a start is typed.

A **Duty End** or **Block Hour** typed by hand is kept as it is typed, and is not overwritten
when a flight time is amended. A row whose block hour was printed by the roster keeps that
figure until one of its flight times is amended. Amending the **Sector** also refreshes a
block hour that came from the times, because the sector says which time zone each end is in.

#### Exporting

The **Roster Preview & PDF** panel builds the roster as a PDF. The preview table and the
generated file both use the **Excel format** headings — Date, Day, Duty, Sector, Duty Start,
Dep Time, Arr Time, Duty End, Duty Period, Block Hour — matching the roster worksheet.
There is no other heading style; an uploaded PDF is relabelled into this layout.

What the preview shows is exactly what the PDF contains. **Export Roster as PDF** opens the
file in a new page, where it can be viewed, printed or saved. If the popup is blocked the
file is downloaded instead. Set the crew name first; the filename is
`GBA-Roster-<crew>-<date>.pdf`. The PDF is A4 portrait and fits the whole roster on
one page whenever it stays legible (the row height shrinks to use the page, down to
3.4 mm, and the footer keeps its own room at the bottom); a much longer roster
pages over normally.

### Editing and clearing rows

Every extracted row is shown in an editable table before it is applied, so a reading
mistake is easy to fix. **Clear** empties the import. **Add Flight Duty** adds a duty the
PDF did not contain. Amending a flight time updates the Duty End, Duty Period and Block Hour
that follow from it — see [Amending a time by hand](#amending-a-time-by-hand).

When the rows are applied to a swap request, the roster's block hours (`1:40`) are carried
across as decimal hours (`1.67`), which is the unit the Block Hours field and the block-hour
rules use.

### Sending the rows to a crew member

**Add to Swap Check (Crew A)** and **Add to Swap Check (Crew B)** send the extracted rows to
the first and the second crew member listed in the swap request. Crew A is the one at the top
of the list, Crew B the one below it. Crew B needs a second crew member to exist — otherwise
it says so and nothing is added.

The same roster is normally sent to both crew members, since a swap covers both of them, so
the extracted rows stay in the import after they have been added and can be sent again. Sending
the same roster again does not double the cards: a date can only be carried by one duty day,
so the duty days already on the crew member are replaced by the new ones.

## The Swap Check page

The page holds one panel: **Crew Members & Duty Days**. It starts with two crew slots side by
side as columns — **Crew A** on the left and **Crew B** on the right — so the Roster Import
buttons "Add to Swap Check (Crew A)" and "Add to Swap Check (Crew B)" always have somewhere to
go. On a narrow screen the two columns stack. The header shows how many crew members and duty
days are in the request, and the actions under the crew cards are **Run Swap Check** and
**Clear**. Each crew member card lists the duty days in the request, and has its own
**+ Duty Day** button for adding one by hand.

Each duty day is shown the way the crew roster app lists it: the weekday and the day of the
month in a narrow column on the left (`SUN` over `8`), and the duty itself in a card beside it —
**Duty**, **Sector**, **Duty Start** and **Duty End**. Click the day number to change the date.
A second sector on the same day gets its own row with the same date.

**A date can only be carried by one duty day.** A duty day added with a date another duty day
already holds replaces it, and the same goes for a duty day whose date is changed to a date
another one holds: the newest wins and the older card is removed. The other crew member still
carries that date, so the pairing follows whatever the new card is set to.

There is no duty type column: the type follows the duty code — `DO`, `AL` and `SL` are days off, a
standby code (`H04`, `H14`) is a standby, `DUTY`, `NDA`, `NB` and `DO-R` are duties with no
times and anything else is a flight. The time labels follow the type ("Standby Start",
"DO Starts").

Only a flight shows its full card. The fields a duty does not have are hidden and cleared, the
way the crew roster app lists them:

| Duty code | Card shows |
|---|---|
| `HB 702` (flight) | Duty, Sector, Duty Start, Duty End |
| `H04`, `H14` (standby) | Duty, Standby Start, Standby End |
| `A`, `GD` (other ground duty) | Duty, Duty Start, Duty End |
| `DUTY`, `NDA`, `NB`, `DO-R` (duty with no times) | Duty |
| `DO`, `AL`, `SL` (day off or leave) | Duty |

A duty with no times, a day off or a leave shows only its duty code, so its duty field stays
narrow while the card itself keeps the same size as the others. Every row is the same height, so
the date column lines up all the way down the card, and the remove button sits at the right of
every card. Changing the duty code re-fits the row straight away.

### Choosing the duty days to check

Each duty card has a tick in front of it. **Only the ticked duty days are checked** — the
rules are applied to those days alone, so a swap that covers one or two days is not judged
against the whole roster. Unticked days stay on the form, dimmed, and are left out of the
swap check. The tick is on by default, and the header of each crew member shows how many days
are ticked with a button to **Select all** or **Clear** them. The selection is saved with the
record and restored when it is loaded back into the form.

Days that cannot be ticked — an annual leave, a sick leave, and the `NB` / `NDA` / `A` / `GD` codes covered by the
**Annual Leave (AL) Cannot Be Swapped**, **Sick Leave (SL) Cannot Be Swapped** and
**NB / NDA / A / GD Cannot Be Swapped** rules — are left out of the count and out of the
**Select all** / **Clear** button, so the button always says what it will do: *"23 of 23
selected · 7 not swappable"* with **Clear** means the 23 swappable days are all ticked and the
button unticks them.

A duty day is also locked when **the other crew member has a locked duty on the same date** —
a swap on that date would have to give up a duty that cannot be swapped. The card then says
*"Not swappable — Chan Tai Man has a locked duty that day"*, and tapping the tick does
nothing. The lock lifts as soon as the locked day on the other side is removed, its code is
changed, or the date is changed.

Because a swap is only allowed on the same date, **the two sides of the request follow each
other**: ticking a duty day ticks the same date on the other crew member as well, and unticking
it unticks the other side too. **Select all** also selects the same dates on the other crew
member, and the roster rows added with *Add to Swap Check* tick the matching dates on the other
crew member. **Clear** works on that crew member alone — it never wipes the other crew member's
request — so if one side is left empty the check says so ("Crew B swaps out no duty day"). A day
that cannot be swapped - an annual leave, a sick leave, an NB / NDA / A / GD - is never ticked
this way; it stays
locked.

The header of the panel shows the totals, for example *"2 crew member(s) · 60 duty day(s) ·
32 selected"*, and the verdict repeats how many days were checked.

Under all of a crew member's duty cards sits their **Total Block Hours** — every card added up
and shown as `H:MM`, the same way the roster prints block time (*"4:10"*). When some days are
left unticked, the ticked figure is shown beside it (*"5:00 · 3:45 selected"*), so the total on
the form and the total that will actually be checked are both visible.

Under that is the **After Swap** figure: the block hours the crew member will hold once the
swap is done — the days that are not swapped away stay, and the days swapped away come back as
the other crew member's duty. It is the figure the 50-hour minimum is judged against, so it
moves as soon as a day is ticked or the other crew member's duty changes. Both figures follow
the cards as they are typed, imported, ticked or removed.

The verdict lists every finding: a **✕** is a failed check and rejects the request, a **✓** is a
check that passed, and a **⚠** is a warning — a note that does not reject the request on its own
(the days off average is shown as a warning when the form does not yet hold the three 28-day
periods the rule needs).

Several flights on the same date are **one duty day**, so they share a single card: the duty
and sector carry the whole chain (`HB 702 → HB 703`, `HKG TPE → TPE HKG`), the Duty Start is
the first sector's and the Duty End the last sector's, and the block hours are the sum of the
sectors. A day with more than one sector gives its duty and sector a line of their own so the
whole chain stays readable. The individual sectors are still edited separately in the Roster
Import.

There is no block hours column either. The block hour still comes from the roster's printed
BLOCK column and is kept on the duty, so the block-hour rules and the swap-out minimum are
assessed as before; a duty added by hand gets one worked out from its own times (Duty Start is
65 min before departure and Duty End 30 min after arrival). Change the block in the Roster
Import, where it is still shown in the preview and the exported PDF.

A slot only counts as a crew member once it is named or has at least one dated duty day, so
an empty slot does not satisfy the "at least two crew members" rule.

The **Preceding Duty Days** section has been removed, but the whole roster that is uploaded for
each crew member is taken into account: the rules that judge a working pattern — the rest
period, the hours in 7, 14 and 28 days, the days on duty, the days off, the day-off and
standby rules — are measured on the crew member's **whole roster with the swap applied**. The
days that are not swapped away stay as they are, and the days that are swapped away come back
as the other crew member's duty.

**The selected (ticked) days are the focus of the check.** A finding is only reported when it
touches one of the days in the request, so the rest of the uploaded roster is used as the
context and a problem on a day that is not part of the swap does not reject the request — it
belongs to the roster, not to the swap. Swap that day instead and the finding appears. The
rules themselves are unchanged and still listed in the Rules tab.

The request details - Requester Name, Position, Base and Reason - are no longer asked for.
The requester is taken from the first crew member listed, and the Rule "Reason Mandatory"
has been removed along with them. Position, Base and Reason on older saved records are kept
and still shown in the Records tab.

## The Records tab

Every swap check is saved with who it was for, when it was run, the outcome and the findings.
Each record card shows the requester and the result on the left, the crew member and duty
day count and the timestamp on the right, the findings as a short list, and the duty days of
each crew member as tags. Long lists are cut short — three findings and six duty days, with
the remainder shown as *"more"* — so a card stays readable.

The toolbar filters by result (all / approved / rejected) and searches across the requester,
the crew names and the recorded details. The count beside it shows how many records match.
**Load into form** puts a saved record back on the Swap Check page, and **Export CSV** writes
every record out.

## Responsive layout

The app is built to work on a phone as well as a desktop, and is installable:

- The two crew members sit side by side as columns on a wide screen and stack on a narrow one.
  They stay side by side **down to 700px**, so an iPad mini (744px in portrait) shows both crew
  members and their duty days next to each other. Below 700px — a phone — they stack.
- On a **computer screen** a duty card is a stack: the **duty code on the first line, the sector
  on the second, and the two duty times side by side on the third**. A standby has no sector, so
  its card is the duty code on the first line and **Standby Start with Standby End** on the
  second. A day off is the duty code alone. A phone uses the same stack, with the date strip
  above it.
- A panel that is half a tablet wide — the side-by-side crew members on an iPad mini or an iPad
  in portrait — cannot hold that stack, so **900px down every duty day becomes a form**: the date
  strip with the remove button on the first line and the card under it. It is the phone layout in
  a narrow column, and every box still gets its room.
- The roster rows are a wide table on a desktop and become a **labelled form** on a narrow one —
  each field carries its own name, so nothing is left to guess. Every field is either **half a
  line** or **a whole line**: a short field (the date, the duty code, a time, the period, the
  block) is half, two to a line, and a long one (the sector) takes the whole line. On a phone the
  date shares the first line with the duty code and is the same width as Duty Start, Dep Time and
  the rest, so the whole row is on one grid. On a tablet the date, duty and sector share the first
  line, all three the same width. On a phone every box in the extracted-duty form is **44px tall**
  and the value is **centred** in it, matching the duty cards, while each label stays at the left
  edge.
- A row shows only the fields that can apply to its duty code, so a **day off is just a date
  and a duty code** instead of seven empty boxes. A standby keeps its start, end and period.
  The values are cleared when the code is confirmed, so the preview and the export stay honest.
- The duty card keeps the date column beside it and, on a phone, moves the date to a strip
  above the card. The remove button moves into that strip, and Duty Start/End sit side by side,
  which makes the card noticeably shorter.
- The two duty times always get room for a whole "0810L" plus the clock icon, so a time is
  never cut off inside its box: on a computer they share the third line of the card, each taking
  half of it, and on a 320px phone they take a line each with the clock icon drawn smaller.
- Every date and time box reads in the **roster's own format**, whatever the phone's language
  is set to: a time as `0810L` and a date as `04-Nov-26`. The browser draws a native date or
  time in the device's own format, so the app puts its own text over the field and hides the
  native one — the picker still opens on a tap, and on a mouse-driven screen the native
  segments come back while the field is being typed into. The date strip on a duty card keeps
  the weekday and the day number, the way the crew roster app shows it.
- Every field in a duty card is **the same height on a phone** — the duty code, the sector and
  the two times all sit in 44px boxes, the same height as the date strip above them, so a card
  reads as a grid. That holds in a narrow desktop window too, not only on a touch screen. The
  value is **centred** in its box on a phone, with the label still at the left edge. iOS wraps a
  date or time field in a native box that ignores that height, so on iOS the native look is
  turned off for the time fields and the picker still opens on a tap. That field is then kept
  inline-block rather than block: iOS centres the value of a date or time field in an inline
  box but pushes it to the top in a block box (WebKit bug 139848), so Duty Start and Duty End
  sit in the middle of their boxes, both across and down, like the duty code and the sector.
- Fields are **16px** on a narrow screen so iOS does not zoom the page when one is focused, and
  buttons and the duty-day tick are at least 44px so they are easy to hit. The same rules apply to
  **any touch screen** (`pointer: coarse`), so a phone turned sideways keeps the large type and
  the big tap targets as well, and so does an **iPad in landscape**: the roster rows keep their
  table shape there, but their boxes are still 16px and at least 42px tall, and the remove button
  in a duty card is a 40px tap target.
- Every input on a phone has one of only **two widths**: **half a line** (the date, the duty code,
  the times, the period, the block, a rule threshold) or **a whole line** (the sector, the crew
  name, the records filter and search, the PDF crew name). The duty card follows the same rule —
  the duty code and the sector take a whole line, the two times half each — and the day-off card
  uses the same full-width duty box as every other card. No field sits at a width of its own,
  which is what made the forms look ragged.
- The roster table keeps its column widths and scrolls **inside** the panel, so a narrow window
  never stretches the page sideways.
- The four tabs fit on one line down to 320px instead of clipping the last word.
- The roster preview stays a table and scrolls sideways, because the numbers need the columns.
- Everything is checked at 1180px, 1133px (iPad mini landscape), 1024px, 900px, 834px, 820px,
  768px, 744px (iPad mini portrait), 700px, 667px, 640px, 560px, 440px (iPhone 16 Pro Max), 430px,
  402px, 390px, 375px, 360px and 320px, in all four views and with an iPad user agent: no
  sideways scrolling of the page, no field under 16px and nothing cut off inside a box.

## Saving the roster as PDF

The **Roster Preview & PDF** panel reproduces the GBA roster layout and exports it with
jsPDF:

| Date | Day | Duty | Sector | Duty Start | Dep Time | Arr Time | Duty End | Duty Period | Block Hour |
|---|---|---|---|---|---|---|---|---|---|---|

- Dates are written `01-Nov-26` and times `0810L`, matching the roster sheet; durations are
  shown as `7:20`.
- **Total Block Hours** is shown in the last row of both the preview and the exported PDF:
  the Block Hour column is added up and printed in its own column. Non-flight duties have
  no block, so they do not change the total.
- The **duty day count** and the **days off by code** (`DO`, `DO-R`, `AL`, `SL`) are printed together
  as a tally under the crew name field and at the head of the exported PDF — for example
  *"15 duty day(s) · 8 DO · 0 DO-R · 7 AL"*, with an `SL` column added when the roster holds a
  sick leave. The duty day count leaves out days off and counts
  several flights on the same date as one duty day. The same tally is repeated in the footer of
  every PDF page.
- When a duty day has more than one flight, the date is printed on the first row only and
  the next rows of the same date leave it blank, as the roster sheet does.
- **Export Roster as PDF** opens the file in a new page (a download if the popup is
  blocked). Set the crew name first; the filename is `GBA-Roster-<crew>-<date>.pdf` and the
  page is A4 portrait, holding the whole roster on one sheet — a full month fits on a single
page, and only a much longer roster pages over.
- **Export Roster as CSV** downloads the same table as `GBA-Roster-<crew>-<date>.csv` — one
  row per roster row (the date on the first flight of each duty day), with a final
  `Total Block Hours` row. The file opens directly in Excel.
- The header row repeats on every page and each page is numbered.

## Duty day types

| Type | Fields used |
|---|---|
| **Flight** | date, report/start, end, block hours, flight no. |
| **Standby** | date, standby start, standby end |
| **DO** (day off) | date, DO start, DO end |

A DO that is shorter than the 34-hour minimum automatically rolls its end time forward
until it spans the required local nights, so a 22:00 → 08:00 DO is treated as a valid
2-night day off.

A **leave** — an annual leave `AL` or a sick leave `SL` — is a **day off** with no times at
all: it carries only its date and its code. It is not a duty day, and the tick is locked
because neither of them can be swapped.

## Rules applied

**1. Number of Duty Days in a Swap Request**
- Maximum 10 consecutive duty days, or 5 individual (non-consecutive) duty days.
- If any individual duty swap is not approved, all other swaps are also rejected.
- **A swap is only allowed on the same date** — the duty days each crew member gives up must
  fall on the same dates, so a duty on one day cannot be swapped for a duty on another day. Only
  the ticked duty days are compared; a day left out of the swap is not part of the pairing.

**2. Swap Limitations**
- Block hours are counted **per calendar month**, from the 1st day of the month to its last
  day. A duty may only be swapped out when the crew member is over the minimum in that month
  **and is still over it after the swap** — that is, when both crew members are over 50 hours in
  that month and both are still over 50 hours after the swap. The figures used are the block
  hours of every duty day on the form for that month (on roster stage), less the block hours of
  the ticked days that are swapped out, plus the block hours that are swapped in. Below the
  minimum, swapping-out block hours is not allowed — except DO-to-DO swaps, duty swaps with the
  same block hours, and swap-in duty with higher block hours. A request that spans two months is
  judged month by month, so 40h in November and 30h in December fails both months even though
  the 70h total is over the minimum.
- So, for your November roster (59:40 on roster stage), swapping a 10:25 duty for another duty
  is allowed as long as you are still over 50 hours afterwards: giving up 10:25 and taking in
  0:30 leaves 49:45 (49.75h), and that is rejected.
- **Annual Leave (AL) cannot be swapped** — it is not a duty day, so it can neither be swapped
  out nor taken in place of a duty. While the rule is on, an AL day cannot be ticked at all: the
  tick is locked and the card says "Annual leave — not swappable". The check also rejects a
  request that carries an AL day.
- **Sick Leave (SL) cannot be swapped** — a sick leave is a day off, not a duty day, so it can
  neither be swapped out nor taken in place of a duty. While the rule is on, an SL day cannot be
  ticked: the tick is locked and the card says "Sick leave — not swappable". The check also
  rejects a request that carries an SL day. It is a rule of its own, so sick leave can be
  allowed or not allowed without touching the annual leave rule.
- **NB / NDA / A / GD cannot be swapped** - one rule covers all four codes. `NB` and `NDA` carry no
  duty, so there is nothing to swap, and the ground duties `A` and `GD` cannot be swapped
  either: they can neither be swapped out nor taken in place of a duty. While the rule is on, an
  NB, NDA, A or GD day cannot be ticked: the tick is locked and the card says "No duty
  assignment - not swappable" (or "Duty A - not swappable" / "Duty GD - not swappable"). The
  check also rejects a request that carries one.

**3. Day Off (DO) and Standby Duty**
- A single DO must include 2 local nights and be at least 34 hours. A local night is 8
  hours falling between 2200 and 0800 local time. An additional consecutive DO must be at
  least 24 hours.
- The maximum number of consecutive DO allowed is **4**. The days off counted are the ones the
  crew member holds **after the swap** — the days off that are not swapped away, plus the days
  off taken in from the other crew member. A day off requested (`DO-R`) counts as a DO here, so a
  run of days off is measured across `DO` and `DO-R` alike. An annual leave (`AL`) and a sick
  leave (`SL`) are **not**
  counted as a DO in this rule.
- A day off cannot be followed by duty earlier than 0600. The rule **Earliest Duty Start After DO /
  DO-R / AL** applies to every kind of rest day — a `DO`, a day off requested (`DO-R`), an annual
  leave (`AL`) and a sick leave (`SL`) — and the finding says which one it is about
  (*"earlier than the 06:00L minimum after an AL"*).
- Duty end time is 30 minutes after STA / ATA or end of standby duty period.
- Any swap resulting in a duty end beyond 2330L before a DO is not approved.
- A crewmember shall not be on duty more than 6 consecutive days; duty end on the 6th duty
  day is 2100L.
- Following 2 consecutive DO, the latest duty end on the 12th day is 1830L, followed by DO
  on the 13th and 14th day.
- Standby starting from/after 1100L cannot be followed by a DO.
- The duty day after standby starting 1100L cannot be swapped for duty with check-in earlier
  than 1200L; after standby starting 1200L or onwards, earlier than 1500L.
- D2 and D3 following standby H10 on D1 can only be Flight / Standby duties — not DO,
  training, SNY, GD or company-assigned special duty.

**4. Rest Period**
- Rest commences 30 minutes after actual time of arrival (ATA).
- Minimum rest is 12 hours, or as long as the preceding duty period, whichever is greater.

**5. Duty Hour Limitations**
- Not more than 60 hours in any 7 consecutive days, 105 hours in any 14 consecutive days,
  or 210 hours in any 28 consecutive days.

**6. Days Off Entitlement**

> Cabin Crew shall not be rostered for duty on more than 6 consecutive days between Days Off; but
> i) shall have 2 consecutive Days Off in any consecutive 14 days following the previous 2 consecutive
> Days Off, and
> ii) shall have a minimum of 7 Days Off in any consecutive 28 days, and
> iii) shall have an average of at least 8 Days Off in each consecutive 28 days period, averaged over
> three such periods.

- The first sentence is the **6 consecutive days on duty** rule in group 3.
- **A minimum of 1 Day Off in any 7 days** — every 7-day stretch must hold at least one day off.
- **2 consecutive Days Off in any 14 days** — the longest run of days off in any 14-day stretch must
  be at least 2.
- **At least 7 Days Off in any 28 days** — every 28-day stretch must hold 7 days off.
- **An average of 8 Days Off per 28 days, averaged over three such periods** — over 84 days the
  total days off must be at least 24. When the form does not hold three full periods yet, the
  average is taken over the whole periods that are there and the finding is shown as a **warning**,
  not a failure.
- These are **roster rules**, so they are measured on every duty day on the form for that crew
  member, not only on the ticked days — a swap is judged against the days around it. A window is
  only looked at when the form holds a card for **every day in it**, so a form that is only partly
  filled is never judged on it. **A day off, a day off requested (`DO-R`), an annual leave and a
  sick leave all
  count as a day off.**
- The old **Maximum Consecutive Days Off (4)** rule was replaced by these four, and has since been
  added back in group 3 as **Maximum Number of Consecutive Days Off (DO)** — the longest run of
  days off in the request may not be longer than 4.

## Running

Open `index.html` directly in a browser, or serve the folder:

```
npx serve "C:\Users\aysha\Documents\GBA Swap Check"
```

For installable PWA behaviour (service worker, offline cache) serve over `http://localhost`
rather than `file://`.

### On an iPhone

- **Add to Home Screen** gives the standalone app with the GBA tail-fin icon
  (`apple-touch-icon.png`, built from `Logo.png`) and the short name **Swap Check** under it.
- The text is never enlarged in landscape (`text-size-adjust`), so the layout holds when the
  phone is turned sideways.
- Every field is 16px or larger, so focusing one never zooms the page.
- The tap targets stay at least 44px on a touch screen, in portrait and in landscape.
- The notch, the rounded corners and the home indicator are kept clear: the header, main
  column, footer and toast pad themselves with `env(safe-area-inset-*)`, and the layout uses
  `100dvh` so the address bar does not push the footer off the screen.
- The **date strip can be tapped** to open the iOS date wheel. iOS opens its own picker on a
  real tap but not reliably on a scripted one, so on iOS the hidden date field takes the tap
  itself instead of the page calling `showPicker()`.
- Keyboard hints are set per field: duty codes and sectors capitalise (`autocapitalize`
  characters), crew names capitalise words, and every field turns off auto-correction and
  spell-check. Times and numbers never become blue phone links (`format-detection=telephone=no`).
- iOS's own search and select chrome is replaced: the records search has no inner shadow or
  native clear button, and the records filter draws the same chevron on every phone.
- A tapped button does not flash a grey box (`-webkit-tap-highlight-color`), a long press on
  the date strip or a button does not start a text selection, and the tables scroll sideways
  smoothly without dragging the page with them.
- With no file to drag, the drop zone reads **Choose a roster PDF / from the Files app** on
  a touch screen, and **Choose File** opens the iOS document picker.

### App icon

The icon is the GBA tail fin from `Logo.png`, laid out square on a soft brand wash, with the
artwork's own transparent padding ignored so the fin is centred:

| file | size | used for |
| --- | --- | --- |
| `icon-192.png` | 192x192 | home screen, browser tab |
| `icon-512.png` | 512x512 | install prompt, splash screen |
| `icon-maskable-512.png` | 512x512 | Android adaptive icon - the fin sits inside the 80% safe circle, so no launcher shape clips it |
| `apple-touch-icon.png` | 180x180 | iPhone and iPad home screen |

All four are opaque (iOS paints transparency black) and are listed in `manifest.json` and in
the service worker `ASSETS` list. Run `make-icon.ps1` to rebuild them from `Logo.png`: it
measures the visible fin, ignores the file's transparent padding, centres it and writes all
four sizes.

### Updates and the offline cache

The service worker keeps the app working with no connection, but it must never
pin an old release:

- **The page** is fetched from the network first. Online, a new release appears on
  the next load; offline, the cached copy is used.
- **The install step** fetches each file with `cache: "reload"`, which skips the
  browser's HTTP cache, so a new version cannot be installed with a stale copy.
- **Every other file** is served from the cache immediately.
- Bump `CACHE` in `sw.js` (`gba-swap-check-vNN`) on each release so the old cache
  is dropped when the new worker activates.

## Data

All data stays local in `localStorage` under `gbaswapcheck.v2` (records) and
`gbaswapcheck.rules.v2` (rule settings). Nothing is transmitted anywhere.

Use **Records → Export CSV** for a backup.
