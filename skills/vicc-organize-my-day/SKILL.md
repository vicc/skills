---
name: vicc-organize-my-day
description: "Plan a day around calendar commitments, priorities, deadlines, and repeatable routines. Invoke explicitly with $vicc-organize-my-day or by asking to use this skill. Checks uncertain invitations, proposes realistic uninterrupted work blocks, and explains tradeoffs using productivity research and Atomic Habits. Do not invoke automatically for general productivity or calendar questions."
---

# Organize my day

Run this workflow only when the user explicitly invokes `$vicc-organize-my-day` or asks to use this skill by name. A general request to plan a day is not an implicit invocation. Continue an already invoked session without requiring repeated invocation.

Produce a suggested calendar plan for the requested day. Calendar edits, RSVPs, cancellations, and messages are separate actions: perform them only when the user explicitly requests them. A planning answer such as “that meeting isn't happening” changes the draft, not the calendar.

Read [the user defaults](references/user-defaults.md); apply current instructions over those defaults. Read [the research reference](references/productive-day-research.md) before planning. Use its task-specific methods and evidence limits; do not conduct fresh research unless an unresolved factual question requires it.

## 1. Check the calendar before asking about tasks

1. Establish the user's local date, current time, and timezone from client context. Resolve conflicting or missing timezone information before assigning clock times. For today, plan only the remaining day unless the user requests a retrospective.
2. Discover the connected calendar's read tools. List available calendars and read the requested local day's events, including events overlapping its boundaries. Follow pagination and recurring-instance details. Use the user's chosen calendars; otherwise inspect personal/work calendars that represent their commitments, excluding holidays and unrelated shared/resource calendars. State coverage so missing calendars cannot masquerade as free time.
3. Read details needed to distinguish start/end, all-day status, timezone, cancellation, busy/free transparency, organizer, location, and **the user's own** RSVP. Do not use another attendee's RSVP or the event's overall “confirmed” status as proof of the user's attendance. Deduplicate copies of the same invitation without dropping separate commitments.
4. Classify each relevant event:
   - Canceled or declined by the user → exclude from reserved time.
   - Accepted, or a definite event organized by the user → preserve as a commitment.
   - User RSVP is tentative or needs action; title/metadata says tentative/hold → ask whether it is still happening, even when its overall status says confirmed.
   - RSVP is absent → check whether this is a self-created event with no RSVP expected. Otherwise ask if attendance remains intended; absent data is not a decline.
   - All-day, free/transparent, or ambiguous personal block → inspect its meaning; ask only if whether it occupies time changes the plan. An all-day reminder does not automatically consume the day.
5. Present uncertain events together with their times: “Are these still happening: …?” Let the user keep, release from this plan, or leave each uncertain. Track a released event as pending calendar cleanup, separately from free time in the draft. If a grouped answer is ambiguous about which events it covers, clarify the affected events before any write. Keep unresolved events provisionally reserved and label them; silence must not create free time. Flag overlapping commitments for the user's decision rather than silently choosing one.

If access fails or only busy windows are available, state what cannot be checked and ask for the missing event details or calendar access. Continue task intake, but label any plan provisional; never claim to have checked RSVP status without event details.

## 2. Ask only questions that change the plan

Use the conversation and calendar to prefill known facts. Ask at most three short questions per round, grouping related facts. Use the async question tool when available, otherwise ask in chat and wait. Do not invent answers while waiting; independent event review can continue.

Start with the highest-impact missing information:

1. **Outcomes, order, and urgency:** “What do you want finished today, in what priority order, and what is actually due when?” Separate a hard due time, a preferred target, and an optional task. Include preparation, submission, or review time before the deadline, not just task start time. Distinguish project rank from fixed-time commitments and protected practice. Ask whether breadth across projects or finishing the top project matters more if capacity is tight; list order alone is not a confirmed ranking.
2. **Capacity:** “When do you want to stop, what non-calendar commitments or travel should I protect, and how is your energy today?” Ask about known best focus times only if not already supplied. Do not infer a morning preference or extend the day without agreement. If a usual lunch routine is saved, apply it and state it as an overridable default. Otherwise ask whether the user wants a dedicated lunch block and, if yes, its duration and whether its time is regular or flexible. Keep meals separate from recovery breaks.
3. **Execution system:** For the most important unclear task, ask what “done today” means, its next visible action, approximate duration, and what blocks starting. Ask about other tasks only when those answers change feasibility or order.

Branch instead of delivering a questionnaire:

- Vague project → identify a concrete finishable outcome and first action before estimating a block.
- Hard deadline → check exact local date/time and dependencies; schedule backward from completion.
- Waiting on someone → identify the user's next available action and an alternative task; do not assume a response arrives on time or send a message on their behalf.
- Avoided or recurring action → ask which existing routine could cue it and what setup/friction prevents starting. Suggest a tiny opening action, not a smaller final requirement.
- Unknown duration → offer labeled estimates and draft the plan when the user delegates estimation; do not repeat requests for durations. State what each estimate includes and its uncertainty. Separate hands-on preparation, unattended runtime, and inspection/retries so a print can run alongside other work. Distinguish a demo from full implementation, review, and verification; a time allocation is not a completion guarantee.
- Too much work → show available capacity and the shortfall, recommend a tradeoff, and get the user's choice before reducing a required outcome or moving a commitment.

When the user says “use your best estimates,” resolve only missing facts that prevent a usable draft. Put remaining uncertainty beside the affected block and expose what will not fit. Stop questioning once remaining unknowns cannot materially change the suggested order or feasibility. Clearly label minor assumptions.

### Save usual routines without turning exceptions into defaults

When the user asks to remember their usual lunch routine, record their explicit usual-routine answer in `references/user-defaults.md`, including dedicated block yes/no, duration, fixed time or flexible window, timezone when a time is given, and date confirmed. Keep populated preferences local and out of commits or PRs; the distributed reference is only a blank template. If the user has not authorized persistence, use the answer for the current session only. Keep missing fields marked unknown; never infer a recurring preference from today's exception. Apply the saved routine next time without asking again unless the user changes it or a calendar conflict requires a decision. A change for today overrides today's plan only. “Remember” or “use this as my default from now on” authorizes persistence. “Usually” alone describes a routine; it updates a saved default only when the user has already authorized remembering that routine. If scope is unclear and would change future plans, ask whether this is today-only or the new usual routine.

Use the host's supported memory mechanism for explicit remember/correction requests when available, in addition to the skill reference. Follow host rules; do not edit generated memory files. If persistence fails, say so rather than claiming the preference is saved. Do not store calendar guest details or a whole day's schedule as personal preferences.

## 3. Build the suggested calendar

Apply constraints in this order because task preferences cannot override commitments or deadlines:

1. Reserve confirmed events and unresolved holds; include known travel, preparation, meals, personal commitments, and the user's stop time. Show any proposed transition or recovery buffers as estimates.
2. Place deadline-bound work and prerequisites before their due times. Check that work can finish, not merely begin, in time. If impossible, explain the conflict and ask for a tradeoff.
3. Schedule projects in the user's stated priority order after fixed deadlines and dependencies. If a different order would help, propose the tradeoff instead of silently reordering. Classify practice by its purpose (for example, interview preparation, recall, or skill development), ask its importance relative to the projects and any upcoming interview/deadline when unknown, and choose its placement from those answers, task demands, and reported alertness. Never default practice to after the first break merely because that worked once. Favor a single uninterrupted block for each demanding outcome when it fits commitments, deadlines, meal windows, and the stop time. Treat reported energy as a soft preference among feasible schedules, not unavailable time, unless the user explicitly makes it a firm constraint. Do not reserve an entire low-energy period as downtime or split a task solely to avoid it. Compare a continuous block through that period with another continuous placement before considering a split; explain the priority/energy tradeoff. If alertness is unknown, use a feasible open period and label this as a scheduling choice, not a biological optimum.
4. Batch compatible routine admin within required response windows. Do not apply batching when it would miss a deadline or an urgent responsibility.
5. Match method to task and justify placement separately: interview practice is cognitively demanding rehearsal, so protect attention and preserve supplied timers, explanation/test-case goals, and no-AI/no-editorial conditions. Prefer an available alert period when that fits its priority and deadline; a break before it is an option, not a required sequence. Retrieval studies support learning methods, not a universal hour for coding interviews or proof of better interview performance. Use closed-book retrieval for learning; optional walking for idea generation when feasible and wanted; separate idea evaluation from generation. Do not prescribe walking for all problem solving.
6. Leave explicit recovery and contingency space, sized to the user's constraints and estimates. Do not fill every gap or enforce a universal 25/5, 50/10, or 90-minute cycle. If required work consumes the available capacity, expose that conflict instead of hiding breaks or shortening tasks.
7. For an avoided or repeated task, attach a concrete cue and easy start: “After [existing event/routine], open [material] and do [first action].” Prepare the environment and identify a visible completion signal. Atomic Habits informs these repeatability choices; it does not establish an optimal timetable.
8. Split demanding work only when a fixed commitment, deadline, explicit user preference, or task dependency requires it, or when the user chooses the tradeoff. First move flexible breaks or lunch within their allowed windows to preserve continuity; do not delete recovery or meals. Name the reason for any necessary split and include a brief next-action note inside the block estimate so resumption is concrete. Ordinary low energy alone is not a reason to split.

Before presenting or revising a timed plan, read the current local time. Retain elapsed blocks only if the user says they started/completed them or explicitly wants the original timetable preserved; otherwise schedule remaining work from now and show any lost capacity. Keep the agreed stop time. Check all intervals, travel, dependencies, deadlines, remaining-day boundaries, and stop time. Proposed work must not overlap reserved events. If existing events overlap, flag the unresolved clash. Recheck calendar data if the user reports changes or the planning conversation crosses a relevant event boundary; refresh before any separately authorized calendar write.

## 4. Present a reviewable proposal

Lead with the date, timezone, the day's main outcome, and a short explanation of the ordering strategy. Identify the role of priority, deadlines, and task demands before showing the timetable. Then show a compact chronological table: **Time | Event or task | Status / intended result**. Distinguish existing commitments, unresolved holds, proposed work, and breaks. Include each task's first action in its row when it helps starting.

After the table, state:

- Give two or three concrete reasons for the order immediately, including the main tradeoff. Distinguish research-supported principles from convenience and estimated durations; the user should not need a separate “why this schedule?” turn.
- Any assumptions, unresolved events, and work that does not fit. Never silently drop a requested task.
- A concrete fallback if the day slips: which flexible block could move and which deadline/commitment must remain. Obtain a decision for changes to required scope.

Ask for corrections to the proposal. Do not turn presentation into a calendar-write approval flow unless the user requests adding or changing events.

## 5. Publish and reconcile when requested

When the user requests calendar writes, use existing authorization without asking again. Refresh the day and current time, match existing blocks, and add/update only the latest agreed plan; retries must not create duplicates. If elapsed time makes that plan infeasible, show the concrete adjustment before materially reducing scope or changing agreed times.

- Track separate actions for new blocks, updates, RSVP changes, notes, and deletion. A user saying an event is not happening releases it from the draft but does not authorize deleting it or notifying its guests.
- If a released event still overlaps the approved plan and no cleanup action was authorized, ask one concise question about that specific event while completing independent authorized writes. Surface this during publishing, rather than leaving a hidden conflict for the user to discover afterward.
- For explicitly requested declines or cancellations, identify the exact event, carry the user's requested note, and use the connector's notification controls. “Need to reschedule” is a decline note, not authorization to book a replacement. Do not claim notification delivery merely because a write succeeded.
- Create solo work blocks without guests or video meetings; explicitly disable automatic conference creation when the API supports it. Include concrete outcomes, useful task links, and starting cues in descriptions. Do not copy speculative estimates into event titles as completion promises.
- Re-read the resulting day and verify dates, timezone, times, duplicates, requested responses, and removals. Verify RSVP notes when the tool exposes them; otherwise report submission rather than independently verified storage. Report any remaining old hold or conflicting event plainly.

Cite the bundled sources when explaining an empirical claim; keep ordinary planning advice concise. Never claim the combined schedule is scientifically validated. Success is a feasible, user-reviewable plan with its uncertainties visible, not maximum calendar occupancy.
