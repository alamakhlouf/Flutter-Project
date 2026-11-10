# Feature 07 — Workshops

**Owner:** Member 7 | **Dependencies:** Features 01 and 02

## Goal
Providers organize workshops; customers and other providers can discover and register. A workshop is a scheduled event, not a service listing.

## Organizer features (provider)
- Create workshop.
- View workshops they organize.
- Edit own workshop.
- Publish/unpublish and cancel own workshop.
- View participant list/count for own workshops.

## Participant features
Both customers and service providers can:
- Browse/search/filter published workshops.
- Filter by category, date, and availability.
- View workshop details.
- Register.
- View own registrations.
- Cancel own registration when permitted.

A provider can participate in a workshop organized by another provider.

## Suggested workshop fields
`id(UUID)`, `organizerId(UUID)`, `title`, `description`, `category`, `coverImageUrl`, `startDateTime`, `endDateTime`, `location`, `capacity`, `registrationDeadline`, `status`, timestamps.

Workshop status: `DRAFT`, `PUBLISHED`, `CANCELLED`, `COMPLETED`.

Registration fields: `id(UUID)`, `workshopId(UUID)`, `participantId(UUID)`, `status`, `registeredAt`, `cancelledAt`.
Registration status: `REGISTERED`, `CANCELLED`.

## Rules
- Only PROVIDER creates workshops.
- Organizer manages only workshops they own.
- CUSTOMER and PROVIDER can register for published workshops.
- Prevent organizer self-registration by default.
- Prevent duplicate active registrations, registration after deadline, and over-capacity registration.
- Active participant count is derived from active registrations.
- Participant can cancel before configured deadline.
- Do not silently delete workshops with registrations; cancel/unpublish instead.
- No waitlist, tickets, payments, certificates, QR attendance, or streaming initially.

## Screens
Workshop discovery; search/filters; details; create/edit; my organized workshops; participants (organizer only); my registrations; confirmation/cancellation; full/closed/cancelled states.

## Acceptance criteria
Providers manage own workshops; customers and providers register for other providers' published workshops; backend prevents duplicates, late registration, and over-capacity; organizer sees participants only for own workshops.
