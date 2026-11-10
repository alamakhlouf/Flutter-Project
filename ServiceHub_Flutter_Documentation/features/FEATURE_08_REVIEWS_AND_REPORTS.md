# Feature 08 — Reviews & Report Submission

**Owner:** Member 8 | **Dependencies:** Features 01, 02, 03, and 05

## Part A — Reviews
Customer:
- Review an eligible completed booking.
- Rate 1–5 stars and add optional comment.
- View reviews on service/provider pages.
- See average rating and review count.

Provider:
- View reviews received on own services.
- Cannot edit customer reviews initially.

Fields: `id(UUID)`, `bookingId`, `customerId`, `providerId`, `serviceId`, `rating`, `comment`, timestamps.

Rules: only the customer owning a COMPLETED booking can review; one review per booking; rating 1–5; backend validates.

## Part B — Report submission
Customer, provider, and supplier:
- Open report form from supported content.
- Select reason and add optional description.
- Submit report and see confirmation.
- Optionally view only their own submitted reports/status.

Targets: user/provider, service, supplier, product, workshop, or other supported content.
Reasons: inappropriate content, fraud/misleading information, harassment, spam, safety concern, other.

Fields: `id(UUID)`, `reporterId`, `targetType`, `targetId(UUID)`, `reason`, `description`, `status`, timestamps.

## Critical mobile/backoffice boundary
Flutter supports report submission only. Do not create an Admin Reports screen, show all reports, or add resolve/dismiss/assign/moderation actions. No admin dashboard. Admin moderation is future web-backoffice functionality. Backend may have protected admin endpoints, but Flutter must not expose or call them.

## Screens
Review form; service/provider reviews list; report form; submission confirmation; optional My Submitted Reports (reporter-owned only).

## Acceptance criteria
Only eligible completed bookings can be reviewed; duplicate reviews prevented; authenticated users can submit reports; no mobile moderation/admin report access.
