# Authorized review follow-up

Use the host automation tool when the host permits monitoring a specific PR this way and the user has authorized it. Reuse an existing follow-up for this PR. Name a new one `Vicc Review Until Clean: <owner>/<repo>#<pr-number>`.

Use this prompt to resume without copying the workflow. Keep its state or the accessible reference current after each pass.

```text
Use $vicc-review-until-clean to resume the review pass for <repo>#<pr-number>: <pr-url>.
Checkout: <path>. Base: <branch/sha>. Head: <branch/sha>.
Latest GitHub request: <comment-id/timestamp>.
Review, validation, and finalization state: <records or accessible state reference>.
Apply the skill's Review state, monitoring, and completion rules. Persist the updated state after each pass.
```
