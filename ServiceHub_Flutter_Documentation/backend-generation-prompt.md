# Prompt — Generate the ServiceHub Spring Boot Backend

Act as a senior Java/Spring Boot developer. Generate a complete but intentionally simple REST API for the ServiceHub Flutter mobile app and its future web administration backoffice. Prefer readable conventional Spring Boot code. Do not overengineer.

## 1. Technology
- Java 17 or compatible LTS.
- Spring Boot 3.x, Maven.
- Spring Web, Spring Data JPA, PostgreSQL.
- Spring Security, JWT, BCrypt.
- Bean Validation and Swagger/OpenAPI.
- Lombok only if it improves readability.

Use simple packages: `controller`, `service`, `repository`, `entity`, `dto`, `security`, `exception`, `config`. No microservices, CQRS, event sourcing, Kafka, Redis, WebSockets, or complex frameworks.

## 2. UUID requirement — mandatory
Every entity primary key must be `UUID`, generated in backend with `UUID.randomUUID()` or a compatible JPA UUID strategy. Never use Long, integer IDs, Mongo ObjectId, or numeric string IDs. All foreign keys and API path IDs use UUID. Flutter treats IDs as strings.

Example:
```java
@Id
@GeneratedValue
private UUID id;
```
Configure UUID mapping correctly for the selected PostgreSQL/JPA versions.

## 3. Authentication and authorization
Roles: `CUSTOMER`, `PROVIDER`, `SUPPLIER`, `ADMIN`.
- Public mobile registration allows CUSTOMER, PROVIDER, SUPPLIER only.
- Never allow self-registration as ADMIN.
- Create admin only through a controlled seed/manual process.
- JWT authentication and BCrypt password hashing.
- Endpoints: `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me`.
- Enforce roles and ownership in backend service methods.
- Derive current user from authenticated principal. Never trust client-supplied user/provider/supplier/reporter IDs as proof of identity.
- Prevent role escalation through profile updates.
- Admin endpoints require ADMIN. They are reserved for the future web backoffice, not Flutter.

## 4. Entities
Use JPA entities, UUID IDs, relationships, timestamps, validation, and DTOs. Never expose JPA entities directly.

### User
`id UUID`, `fullName`, `email unique`, `passwordHash`, `role`, optional `phone`, optional `profileImageUrl`, `createdAt`, `updatedAt`.

### Service
`id UUID`, `provider User`, `title`, `description`, `category`, `price BigDecimal` (or agreed price description), optional `imageUrl`, `active`, timestamps.

### InventoryItem
`id UUID`, `provider User`, `name`, optional `description`, `quantity`, `unit`, optional `lowStockThreshold`, timestamps. Quantity cannot be negative.

### Booking
`id UUID`, `customer User`, `provider User`, `service Service`, `serviceTitleSnapshot`, `priceSnapshot BigDecimal`, `description`, `preferredDateTime`, `status`, timestamps.
Statuses: PENDING, ACCEPTED, REJECTED, IN_PROGRESS, COMPLETED, CANCELLED.
Transitions: PENDING → ACCEPTED/REJECTED/CANCELLED; ACCEPTED → IN_PROGRESS/CANCELLED; IN_PROGRESS → COMPLETED. Validate in service layer.

### SupplierProduct
`id UUID`, `supplier User`, `name`, `description`, `category`, `price BigDecimal`, optional `imageUrl`, optional `quantityAvailable`, `available`, timestamps.

### ProductOrder
`id UUID`, `customer User`, `supplier User`, `totalAmount BigDecimal`, `status`, timestamps.

### OrderItem
`id UUID`, `order ProductOrder`, `product SupplierProduct`, `productNameSnapshot`, `unitPriceSnapshot BigDecimal`, `quantity`, `lineTotal BigDecimal`.

An order belongs to one supplier initially. Server calculates totals and validates availability/quantity; never trust client totals.
Statuses: PENDING, ACCEPTED, REJECTED, PROCESSING, COMPLETED, CANCELLED.
Transitions: PENDING → ACCEPTED/REJECTED/CANCELLED; ACCEPTED → PROCESSING/CANCELLED; PROCESSING → COMPLETED.

### Workshop
`id UUID`, `organizer User (PROVIDER)`, `title`, `description`, `category`, optional `coverImageUrl`, `startDateTime`, `endDateTime`, `location`, `capacity`, `registrationDeadline`, `status`, timestamps.
Statuses: DRAFT, PUBLISHED, CANCELLED, COMPLETED.

### WorkshopRegistration
`id UUID`, `workshop`, `participant User`, `status`, `registeredAt`, optional `cancelledAt`.
Statuses: REGISTERED, CANCELLED.
Only providers create workshops. Customers and providers can register for published workshops. A provider can participate in another provider's workshop. Prevent organizer self-registration by default, duplicate active registrations, late registration, and over-capacity registration. Count active registrations accurately. No waitlist initially.

### Review
`id UUID`, `booking`, `customer`, `provider`, `service`, `rating`, optional `comment`, timestamps.
Only customer owning a COMPLETED booking can review it. One review per booking. Rating 1–5.

### Report
`id UUID`, `reporter User`, `targetType`, `targetId UUID`, optional `targetTitle` (Service title, User full name, Workshop title, etc.), `reason`, optional `description`, `status`, timestamps.
When returning `ReportDTO` (e.g. for `/api/admin/reports`), include `targetTitle` (or `targetName`) and `reporterName` so administrators can immediately see the title of the reported service or full name of the reported profile.

### Notification
`id UUID`, `recipient User`, `title`, `message`, `type`, optional `relatedEntityType`, optional `relatedEntityId UUID`, `read`, `createdAt`.
Create simple notifications from service methods; no message broker.

## 5. REST endpoints

### Auth/profile
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `GET /api/users/me`
- `PUT /api/users/me`

### Services
- `GET /api/services` (search/category/page/size)
- `GET /api/services/{id}`
- `POST /api/services` (PROVIDER)
- `PUT /api/services/{id}` (owner)
- `PATCH /api/services/{id}/active` (owner)
- `DELETE /api/services/{id}` (owner)
- `GET /api/providers/{providerId}/services`

### Inventory
- `GET /api/inventory`
- `GET /api/inventory/{id}`
- `POST /api/inventory` (PROVIDER)
- `PUT /api/inventory/{id}` (owner)
- `PATCH /api/inventory/{id}/quantity` (owner)
- `DELETE /api/inventory/{id}` (owner)

### Bookings
- `POST /api/bookings`
- `GET /api/bookings/my`
- `GET /api/bookings/{id}`
- `PATCH /api/bookings/{id}/status`
- `PATCH /api/bookings/{id}/cancel`

### Suppliers/products/orders
- `GET /api/suppliers`
- `GET /api/suppliers/{id}`
- `GET /api/products` (search/category/page/size)
- `GET /api/products/{id}`
- `POST /api/products` (SUPPLIER)
- `PUT /api/products/{id}` (owner)
- `PATCH /api/products/{id}/availability` (owner)
- `DELETE /api/products/{id}` (owner)
- `POST /api/orders`
- `GET /api/orders/my`
- `GET /api/orders/{id}`
- `PATCH /api/orders/{id}/status`
- `PATCH /api/orders/{id}/cancel`

### Workshops
- `GET /api/workshops` (search/category/date/availability/page/size)
- `GET /api/workshops/{id}`
- `POST /api/workshops` (PROVIDER)
- `PUT /api/workshops/{id}` (organizer)
- `PATCH /api/workshops/{id}/publish` (organizer)
- `PATCH /api/workshops/{id}/cancel` (organizer)
- `GET /api/workshops/my/organized` (PROVIDER)
- `GET /api/workshops/my/registrations`
- `GET /api/workshops/{id}/participants` (organizer only)
- `POST /api/workshops/{id}/registrations`
- `DELETE /api/workshops/{id}/registrations/me`

### Reviews and mobile reports
- `POST /api/reviews`
- `GET /api/services/{serviceId}/reviews`
- `GET /api/providers/{providerId}/reviews`
- `POST /api/reports`
- `GET /api/reports/my` (optional; reporter-owned only)

### Admin & moderation endpoints (ADMIN)
- `GET /api/admin/reports` (search/status/page/size)
- `GET /api/admin/reports/{id}`
- `PATCH /api/admin/reports/{id}/status` (UPDATE status to RESOLVED / DISMISSED / PENDING)
- `PATCH /api/admin/users/{id}/block` (Block reported user account)
- `DELETE /api/admin/services/{id}` (Delete reported service listing)
All `/api/admin/**` routes require ADMIN role authorization.

### Notifications
- `GET /api/notifications`
- `PATCH /api/notifications/{id}/read`
- `PATCH /api/notifications/read-all` (optional)

## 6. API conventions
- JSON DTO request/response; no entity serialization.
- UUID path parameters.
- Bean Validation with `@Valid`.
- Correct HTTP status codes and consistent global error response.
- Never return stack traces to clients.
- ISO-8601 date/time.
- `BigDecimal` for money.
- Pagination on larger lists.
- Transactions for order creation and workshop registration.
- Validate ownership and state transitions in service layer.

Example error:
```json
{
  "timestamp": "2026-11-09T12:00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Workshop is full",
  "path": "/api/workshops/..."
}
```

## 7. Images
Store image URLs in entities; do not store binary files in PostgreSQL. Initially accept URLs if upload handling is unnecessary. If implementing uploads, validate file type/size and use configurable storage. Never hardcode credentials.

## 8. Development seed data
Provide local-only seed data for one CUSTOMER, one PROVIDER, one SUPPLIER, one ADMIN, plus sample services, inventory, products, and workshops. Document development credentials and warn that they must not be used in production.

## 9. Basic tests
Test registration/login, role restrictions, ownership, non-negative inventory, booking transitions, order totals, workshop capacity/duplicate registration, review eligibility/uniqueness, report submission/admin-only moderation, and notification ownership.

## 10. Deliverables
Complete Maven project; PostgreSQL environment configuration; entities/repositories; DTOs/validation; services/business rules; controllers; JWT security; global exception handling; Swagger; seed data; basic tests; `.env.example`; README with setup/run/test/API docs; concise API contract with roles and example payloads.

## 11. Keep it simple
Do not add microservices, Kafka/RabbitMQ, Redis, WebSockets, complex caching, payment gateway, chat, complex offline synchronization, or unrequested features. Prioritize readable code, easy local setup, straightforward Flutter integration, and secure role/ownership validation. Ensure the project compiles, starts, connects to PostgreSQL, and documented endpoints match the implementation.
