# ServiceHub — Project Context

## Product
ServiceHub is a local services marketplace connecting customers, service providers, and suppliers. Customers discover/book services, order products, join workshops, review completed services, and submit reports. Providers manage services, inventory, bookings, and workshops. Suppliers manage products and customer orders.

Two planned clients:
1. Flutter mobile app — scope of this documentation.
2. Web administration backoffice — planned later.

## Mobile roles

### Customer
- Register, sign in, and manage profile.
- Browse/search/filter services and view provider details.
- Create and manage own bookings.
- Browse suppliers/products and place/track orders.
- Browse workshops, register, and cancel own registration when allowed.
- Review a service after a completed booking.
- Submit reports about supported users/content.
- View relevant personal activity and notifications.

### Service Provider
- Manage own profile and services.
- Manage own inventory items and quantities.
- View/process bookings for own services.
- Create/manage own workshops.
- Register for workshops organized by other providers.
- View participants of own workshops.
- View reviews received on own services.
- Submit reports when appropriate.

### Supplier
- Manage supplier profile and product listings.
- Update product details, price, availability, and stock.
- View/process orders for own products.
- View order history and submit reports when appropriate.

### Admin
Admin is a backoffice role, not a mobile operator.
- No admin dashboard in Flutter.
- No reports section or moderation actions in Flutter.
- No admin user/service/workshop management screens in Flutter.
- If an ADMIN account signs in, block mobile feature access and show that administration will be available through the web backoffice.
- Backend authorization is mandatory; hiding UI is not security.

## Functional modules
1. Identity & profiles.
2. Services & catalog.
3. Inventory management.
4. Service booking & requests.
5. Supplier & product orders.
6. Workshops.
7. Reviews & report submission.
8. Role-aware dashboards & notifications.

## Business rules

### Services
- A service belongs to one provider; only its owner can manage it.
- Only active services can be booked.
- Store title, description, category, price/pricing description, image, and availability.

### Inventory
- Inventory belongs to a provider.
- Track name, description, quantity, unit, and optional low-stock threshold.
- Quantity cannot be negative.
- OUT_OF_STOCK when quantity is zero; LOW_STOCK when quantity is above zero and at/below threshold; otherwise IN_STOCK.
- No warehouse/accounting system.

### Bookings
Transitions: PENDING → ACCEPTED / REJECTED / CANCELLED; ACCEPTED → IN_PROGRESS / CANCELLED; IN_PROGRESS → COMPLETED.
Rejected, cancelled, and completed are terminal.
- Customers create bookings for active services.
- Customers only access their own bookings; providers only manage bookings for their services.
- Validate transitions on backend.
- Store service title and price snapshots at booking time.

### Supplier orders
Transitions: PENDING → ACCEPTED / REJECTED / CANCELLED; ACCEPTED → PROCESSING / CANCELLED; PROCESSING → COMPLETED.
- Backend validates product availability/quantity and calculates totals.
- Supplier only manages relevant orders.
- Initially, each order belongs to one supplier.
- No payment gateway in initial scope.

### Workshops
- A workshop is a scheduled event, not a service listing.
- Only providers organize workshops.
- Customers and providers can register for published workshops.
- A provider can participate in another provider's workshop.
- By default, organizer cannot register for their own workshop.
- Prevent duplicate active registrations, late registrations, and over-capacity registration.
- Participant count is based on active registrations.
- Participants can cancel before the configured deadline.
- Initial registration statuses: REGISTERED and CANCELLED.
- No waitlist, ticketing, payments, certificates, QR attendance, or streaming initially.
- Do not silently delete a workshop with registrations; cancel or unpublish it.

### Reviews
- Only the customer who owns a COMPLETED booking can review it.
- One review per booking; rating range 1–5.
- Providers can read reviews on their own services.

### Reports
- Authenticated mobile users can submit reports.
- A report stores reporter, target type, target UUID, reason, optional description, status, and timestamps.
- Mobile can optionally show only the reporter's own reports/status.
- Mobile cannot list all reports or moderate them.
- Admin moderation is reserved for the future web backoffice.

## Shared requirements
Mobile-first UI; role-aware navigation; loading/empty/error/success/offline states; validation; confirmation for destructive actions; search/filtering and pagination where appropriate; image support for profile/service/product/workshop; consistent date/time/currency formatting; understandable API errors.

## Technical direction
### Flutter
- Flutter/Dart; use built-in setState only.
- Do not use Bloc, Provider, Riverpod, GetX, Redux, or another state-management framework.
- Keep API calls in small feature service classes, not in build().
- Use Future/async/await and check mounted before setState after async work.
- Centralize API base URL and token handling.
- Avoid unnecessary abstraction.

### Backend
- Spring Boot REST API.
- Backend prompt uses Spring Data JPA + PostgreSQL as a simple relational baseline. If the team has already chosen MongoDB, change persistence consistently before code generation.
- UUID for every entity ID.
- Straightforward controller/service/repository/entity/DTO/security/exception packages.
