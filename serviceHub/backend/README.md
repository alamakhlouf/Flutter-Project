# ServiceHub Backend

Spring Boot 3 / Java 17 REST API for the ServiceHub marketplace. The default database is MySQL, with UUID entity identifiers, Spring Data JPA, BCrypt, JWT bearer authentication, Bean Validation, and OpenAPI. JPA entities are not returned from API endpoints.

## Run locally

Requirements: Java 17+ and Maven 3.8+. From this directory:

```powershell
$env:DB_USERNAME = "root"
$env:DB_PASSWORD = "your-mysql-password"
$env:JWT_SECRET = "generate-a-random-secret-with-at-least-32-characters"
mvn spring-boot:run
```

The default profile connects to MySQL at `localhost:3306`, database `servicehub_api`. Connector/J is configured with `createDatabaseIfNotExist=true`, so it creates the database on first connection if the configured MySQL account has `CREATE DATABASE` permission. Hibernate's `ddl-auto=update` creates missing tables and updates the schema. The MySQL server must already be installed/running; this application creates the database and tables, not the database server or MySQL user. A separate `servicehub_api` schema is used by default to avoid overwriting any pre-existing `servicehub` database. Swagger UI is at `http://localhost:8080/swagger-ui.html`.

If `JWT_SECRET` is omitted during local development, the API generates a temporary random signing key and logs a warning; JWTs issued with that key stop working after restart. Set `JWT_SECRET` (at least 32 bytes) in the IntelliJ run configuration's environment variables or deployment environment for persistent tokens. Never use a committed/static development key in production.

The `local` profile is an optional isolated H2 mode for tests/development. Run with `$env:SPRING_PROFILES_ACTIVE = "local"` to use in-memory H2 and seed sample records. Its console is at `http://localhost:8080/h2-console` (JDBC URL `jdbc:h2:mem:servicehub`, user `sa`, blank password).

**Local-only credentials for all seeded accounts:** `ServiceHub123!`

| Role | Email |
|---|---|
| CUSTOMER | customer@servicehub.local |
| PROVIDER | provider@servicehub.local |
| SUPPLIER | supplier@servicehub.local |
| ADMIN | admin@servicehub.local |

These credentials and the local JWT secret are development-only. Never use them in production.

## MySQL configuration

Set the environment variables from `.env.example` in your shell/deployment environment. Configure a MySQL user with `CREATE DATABASE` permission (and permissions on the created database). Example:

```powershell
$env:DB_HOST = "localhost"
$env:DB_PORT = "3306"
$env:DB_NAME = "servicehub_api"
$env:DB_USERNAME = "root"
$env:DB_PASSWORD = "your-local-password"
$env:JWT_SECRET = "generate-a-random-secret-with-at-least-32-characters"
$env:DDL_AUTO = "update"
mvn spring-boot:run
```

You may override the full JDBC URL with `DB_URL`; retain `createDatabaseIfNotExist=true` to keep automatic database creation enabled. Table creation/update is controlled by `DDL_AUTO` (defaults to `update`). The `local` profile switches to ephemeral H2 and should not be used when testing MySQL connectivity. The local seed runner creates sample users, including an administrator, only for local development. For production, create the initial ADMIN through a controlled operator-managed process; public registration rejects `ADMIN`. Prefer reviewed database migrations and a restricted database account after initial setup.

## Tests

```powershell
mvn test
```

Tests use the local H2 profile and do not require PostgreSQL.

## Authentication

Register with `POST /api/auth/register` using JSON such as:

```json
{"fullName":"A Customer","email":"person@example.com","password":"password123","role":"CUSTOMER"}
```

Supported public registration roles are `CUSTOMER`, `PROVIDER`, and `SUPPLIER`. Sign in with `POST /api/auth/login`:

```json
{"email":"person@example.com","password":"password123"}
```

Pass the returned token as `Authorization: Bearer <token>`. `GET /api/auth/me` and `/api/users/me` return the authenticated profile. Profile updates cannot change roles or email.

## API contract

All IDs and path parameters are UUIDs. Times use ISO-8601 instants; monetary values are decimal numbers. Paginated catalog endpoints return a stable page shape (`content` and nested `page` metadata including total elements/pages); page defaults to 0 and size to 20 (maximum 100). Validation and domain errors use `{ "timestamp", "status", "error", "message", "path" }`.

| Method and path | Access | Purpose |
|---|---|---|
| `POST /api/auth/register`, `/api/auth/login` | Public | Register or receive JWT |
| `GET /api/auth/me`, `/api/users/me`; `PUT /api/users/me` | Signed in | Read/update own profile |
| `GET /api/services?search=&category=&page=&size=` | Public | Browse active services |
| `GET /api/services/{id}` | Public | Service detail |
| `POST /api/services`; `PUT /api/services/{id}`; `PATCH /api/services/{id}/active`; `DELETE /api/services/{id}` | Provider; owner for mutations | Manage own services; delete deactivates |
| `GET /api/providers/{providerId}/services` | Public | Provider's active services |
| `GET /api/inventory`, `GET /api/inventory/{id}`, `POST /api/inventory`, `PUT /api/inventory/{id}`, `PATCH /api/inventory/{id}/quantity`, `DELETE /api/inventory/{id}` | Provider; owner for item operations | Manage own inventory |
| `POST /api/bookings`, `GET /api/bookings/my`, `GET /api/bookings/{id}` | Customer creates; participants read | Create and view bookings |
| `PATCH /api/bookings/{id}/status` | Provider for the service | Apply valid booking transitions |
| `PATCH /api/bookings/{id}/cancel` | Booking customer | Cancel an eligible booking |
| `GET /api/suppliers`, `GET /api/suppliers/{id}` | Public | Browse supplier profiles |
| `GET /api/products?search=&category=&page=&size=`, `GET /api/products/{id}` | Public | Browse available products |
| `POST /api/products`, `PUT /api/products/{id}`, `PATCH /api/products/{id}/availability`, `DELETE /api/products/{id}` | Supplier; owner for mutations | Manage own listings; delete deactivates |
| `POST /api/orders`, `GET /api/orders/my`, `GET /api/orders/{id}` | Customer creates; participants read | Create/view orders |
| `PATCH /api/orders/{id}/status` | Order supplier | Apply valid order transitions |
| `PATCH /api/orders/{id}/cancel` | Order customer | Cancel eligible order |
| `GET /api/workshops?search=&category=&date=&availability=&page=&size=`; `GET /api/workshops/{id}` | Public (published workshops) | Browse published workshops |
| `POST /api/workshops`, `PUT /api/workshops/{id}`, `PATCH /api/workshops/{id}/publish`, `PATCH /api/workshops/{id}/cancel`, `GET /api/workshops/my/organized`, `GET /api/workshops/{id}/participants` | Organizer/provider | Manage own workshops and view participants |
| `GET /api/workshops/my/registrations`, `POST /api/workshops/{id}/registrations`, `DELETE /api/workshops/{id}/registrations/me` | Customer or provider; not own workshop | Manage own participation |
| `POST /api/reviews` | Customer with completed booking | One review per booking |
| `GET /api/services/{serviceId}/reviews`, `GET /api/providers/{providerId}/reviews` | Public | Read service/provider reviews |
| `POST /api/reports`, `GET /api/reports/my` | Signed-in reporter | Submit/list own reports |
| `GET /api/admin/reports`, `GET /api/admin/reports/{id}`, `PATCH /api/admin/reports/{id}/status` | ADMIN only | **Future web-backoffice only; not a Flutter feature** |
| `GET /api/notifications`, `PATCH /api/notifications/{id}/read`, `PATCH /api/notifications/read-all` | Signed in; own records only | Read personal notifications |

### Example payloads

Create a booking: `{"serviceId":"<service-uuid>","preferredDateTime":"2027-01-15T10:00:00Z","description":"Please call first"}`.

Create an order: `{"items":[{"productId":"<product-uuid>","quantity":2}]}`. The backend validates supplier, stock, and availability, reserves tracked quantity, and calculates totals from current prices.

Create a workshop: `{"title":"Workshop","description":"Details","category":"Home","startDateTime":"2027-02-01T10:00:00Z","endDateTime":"2027-02-01T12:00:00Z","location":"Studio","capacity":12,"registrationDeadline":"2027-01-31T10:00:00Z"}`.

## Business rules

Booking and order transitions are validated in the service layer. Workshop registration locks the workshop row while checking capacity; duplicate active registration, self-registration, expired deadlines, and full workshops are rejected. Product order totals and snapshots are calculated server-side. Inventory quantity and workshop capacity are validated; review submission requires the authenticated customer to own a completed booking.

Images are represented by URLs only. No payment processing, report moderation for mobile, waitlist, or file upload is provided.
