# Feature 03 — Services & Catalog

**Owner:** Member 3 | **Dependencies:** Features 01 and 02

## Customer features
- Browse active services and categories.
- Search by title/description.
- Filter by category and supported criteria such as price/location.
- View service details and provider profile.
- View service images, description, category, price/pricing description, and availability.
- Inactive services cannot be booked.

## Provider features
- List own services.
- Create, edit, activate/deactivate, and delete own services.
- Upload/select service image if supported.
- Manage title, description, category, price/pricing type, and availability.

## Suggested fields
`id(UUID)`, `providerId(UUID)`, `title`, `description`, `category`, `price` or `priceDescription`, `imageUrl`, `isActive`, timestamps.

## Rules
Each service belongs to one provider. Only its owner can manage it. Backend validates ownership. Use pagination/load-more for long lists.

## Screens
Service catalog; search/filter results; service details; provider's services; create/edit service; delete confirmation.

## Acceptance criteria
Customers browse/search/filter/view details; providers manage only their own services; inactive services cannot be booked; loading, empty, and error states work.
