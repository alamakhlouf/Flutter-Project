# Feature 04 — Inventory Management

**Owner:** Member 4 | **Dependencies:** Features 01 and 02

## Goal
Providers track simple stock records for their business.

## Scope
- View/search own inventory.
- Add, edit, and delete inventory items.
- Update stock quantity.
- Configure optional low-stock threshold.
- Display IN_STOCK, LOW_STOCK, and OUT_OF_STOCK states.

## Suggested fields
`id(UUID)`, `providerId(UUID)`, `name`, `description`, `quantity`, `unit`, `lowStockThreshold`, timestamps.

## Rules
- Inventory belongs to a provider; provider manages only own items.
- Quantity cannot be negative.
- OUT_OF_STOCK when quantity is zero.
- LOW_STOCK when quantity is above zero and less than/equal to threshold.
- Otherwise IN_STOCK.
- No warehouse, accounting, forecasting, or automatic booking deductions.

## Screens
Inventory list; add/edit item; update quantity; empty/low-stock states.

## Acceptance criteria
Ownership enforced; quantity changes persist; negative quantity rejected; stock status calculated consistently.
