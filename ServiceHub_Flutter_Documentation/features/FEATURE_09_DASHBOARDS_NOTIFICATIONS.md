# Feature 09 — Role-Aware Dashboards & Notifications

**Owner:** Member 9 | **Dependencies:** Features 01–08

## Customer dashboard
Service discovery shortcut; recent bookings/orders and statuses; upcoming workshop registrations; relevant notifications; profile/activity shortcuts.

## Provider dashboard
Own services; pending/current bookings; low-stock inventory summary; workshops organized and participated in; recent reviews; notifications.

## Supplier dashboard
Product listing summary; pending incoming orders; orders being processed; notifications; product/order/profile shortcuts.

## Notifications
Use simple backend-persisted in-app notifications. No WebSockets or message broker initially.
Examples: booking status updates; order status updates; workshop registration confirmation/cancellation; workshop cancellation or important changes.

Suggested fields: `id(UUID)`, `recipientId`, `title`, `message`, `type`, `relatedEntityType`, `relatedEntityId(UUID optional)`, `isRead`, `createdAt`.

Features:
- List notifications for current user.
- Mark one as read; optional mark-all-as-read.
- Navigate to related detail screen where supported.
- Display unread count.

No admin dashboard in Flutter.

## Acceptance criteria
Dashboard matches role; users see only relevant data; read state persists; loading/empty/error states work.
