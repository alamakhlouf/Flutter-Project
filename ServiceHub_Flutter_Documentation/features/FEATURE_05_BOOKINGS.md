# Feature 05 — Service Booking & Requests

**Owner:** Member 5 | **Dependencies:** Features 01, 02, and 03

## Customer features
- Start booking from an active service.
- Enter request description and preferred date/time.
- Submit booking.
- View own booking list/details/status.
- Cancel own booking when permitted.

## Provider features
- View incoming bookings for own services and filter by status.
- View request/customer details.
- Accept/reject pending booking.
- Mark accepted booking IN_PROGRESS.
- Mark in-progress booking COMPLETED.
- Cancel accepted booking if allowed.

## Status transitions
- PENDING → ACCEPTED / REJECTED / CANCELLED
- ACCEPTED → IN_PROGRESS / CANCELLED
- IN_PROGRESS → COMPLETED
Rejected, cancelled, and completed are terminal.

## Suggested fields
`id(UUID)`, `customerId`, `providerId`, `serviceId`, `serviceTitleSnapshot`, `priceSnapshot`, `description`, `preferredDateTime`, `status`, timestamps.

## Rules
Only active services can be booked. Customer accesses only own bookings; provider manages bookings for own services only. Validate transitions on backend. Keep service title/price snapshots. Do not show invalid actions.

## Screens
Create booking; customer booking list/details; provider incoming requests/details; status confirmation.

## Acceptance criteria
Booking lifecycle works; ownership and transitions are backend-enforced; lists/details show updated status.
