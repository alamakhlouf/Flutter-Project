# Feature 06 — Supplier & Product Orders

**Owner:** Member 6 | **Dependencies:** Features 01 and 02

## Supplier features
- View/edit supplier profile.
- Create, list, edit, activate/deactivate, and delete own products.
- Manage title, description, category, price, image, availability, and optional stock.
- View incoming orders for own products.
- Accept/reject eligible orders.
- Mark accepted orders PROCESSING and processing orders COMPLETED.

## Customer features
- Browse suppliers and available products.
- Search/filter products.
- View product/supplier details.
- Create order with one or more products from one supplier.
- View own order history/details.
- Cancel when permitted.

## Suggested fields
Product: `id(UUID)`, `supplierId`, `name`, `description`, `category`, `price`, `imageUrl`, `quantityAvailable`, `isAvailable`, timestamps.
Order: `id(UUID)`, `customerId`, `supplierId`, `items`, `totalAmount`, `status`, timestamps.
Order item: product ID, product name snapshot, unit price snapshot, quantity, line total.

## Order transitions
PENDING → ACCEPTED / REJECTED / CANCELLED
ACCEPTED → PROCESSING / CANCELLED
PROCESSING → COMPLETED

## Rules
Backend validates product availability/quantity and calculates totals. Supplier manages only own products and relevant orders. Each order belongs to one supplier initially. No payment gateway initially.

## Screens
Supplier list/details; product catalog/details; customer order creation/history/details; supplier product management; incoming orders/details.

## Acceptance criteria
Supplier CRUD and customer ordering work; server calculates totals; ownership and status transitions are enforced.
