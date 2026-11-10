package com.servicehub.dto;

import com.servicehub.entity.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class ApiDtos {
    private ApiDtos() { }
    public record RegisterRequest(@NotBlank String fullName, @Email @NotBlank String email, @NotBlank @Size(min = 8) String password,
                                  @NotNull Role role, String phone, String profileImageUrl) { }
    public record LoginRequest(@Email @NotBlank String email, @NotBlank String password) { }
    public record UserDto(UUID id, String fullName, String email, Role role, String phone, String profileImageUrl) { }
    public record AuthResponse(String token, UserDto user) { }
    public record ProfileUpdate(@NotBlank String fullName, String phone, String profileImageUrl) { }
    public record ServiceRequest(@NotBlank String title, String description, @NotBlank String category,
                                 @NotNull @DecimalMin("0.00") BigDecimal price, String imageUrl) { }
    public record ActiveUpdate(@NotNull Boolean active) { }
    public record ServiceDto(UUID id, UUID providerId, String providerName, String title, String description,
                             String category, BigDecimal price, String imageUrl, boolean active, Instant createdAt) { }
    public record InventoryRequest(@NotBlank String name, String description, @Min(0) int quantity,
                                   @NotBlank String unit, @Min(0) Integer lowStockThreshold) { }
    public record QuantityUpdate(@Min(0) int quantity) { }
    public record InventoryDto(UUID id, UUID providerId, String name, String description, int quantity, String unit,
                               Integer lowStockThreshold, String stockStatus, Instant updatedAt) { }
    public record BookingRequest(@NotNull UUID serviceId, @NotNull Instant preferredDateTime, String description) { }
    public record StatusUpdate(@NotNull Enum<?> status) { }
    public record BookingStatusUpdate(@NotNull BookingStatus status) { }
    public record OrderStatusUpdate(@NotNull OrderStatus status) { }
    public record BookingDto(UUID id, UUID customerId, UUID providerId, UUID serviceId, String serviceTitle,
                             BigDecimal price, String description, Instant preferredDateTime, BookingStatus status, Instant createdAt) { }
    public record ProductRequest(@NotBlank String name, String description, @NotBlank String category,
                                 @NotNull @DecimalMin("0.00") BigDecimal price, String imageUrl,
                                 @Min(0) Integer quantityAvailable, boolean available) { }
    public record ProductAvailability(@NotNull Boolean available) { }
    public record ProductDto(UUID id, UUID supplierId, String supplierName, String name, String description,
                             String category, BigDecimal price, String imageUrl, Integer quantityAvailable, boolean available) { }
    public record OrderLineRequest(@NotNull UUID productId, @Min(1) int quantity) { }
    public record OrderRequest(@NotEmpty List<@Valid OrderLineRequest> items) { }
    public record OrderItemDto(UUID id, UUID productId, String productName, BigDecimal unitPrice, int quantity, BigDecimal lineTotal) { }
    public record OrderDto(UUID id, UUID customerId, UUID supplierId, BigDecimal totalAmount, OrderStatus status,
                           List<OrderItemDto> items, Instant createdAt) { }
    public record WorkshopRequest(@NotBlank String title, String description, @NotBlank String category, String coverImageUrl,
                                  @NotNull Instant startDateTime, @NotNull Instant endDateTime, @NotBlank String location,
                                  @Min(1) int capacity, @NotNull Instant registrationDeadline) { }
    public record WorkshopDto(UUID id, UUID organizerId, String organizerName, String title, String description,
                              String category, String coverImageUrl, Instant startDateTime, Instant endDateTime,
                              String location, int capacity, Instant registrationDeadline, WorkshopStatus status,
                              long participantCount) { }
    public record RegistrationDto(UUID id, UUID workshopId, UUID participantId, WorkshopRegistrationStatus status,
                                  Instant registeredAt, Instant cancelledAt) { }
    public record ReviewRequest(@NotNull UUID bookingId, @Min(1) @Max(5) int rating, @Size(max = 2000) String comment) { }
    public record ReviewDto(UUID id, UUID bookingId, UUID customerId, UUID providerId, UUID serviceId, int rating,
                            String comment, Instant createdAt) { }
    public record ReportRequest(@NotBlank String targetType, @NotNull UUID targetId, @NotBlank String reason,
                                @Size(max = 2000) String description) { }
    public record ReportStatusUpdate(@NotNull ReportStatus status) { }
    public record ReportDto(UUID id, UUID reporterId, String targetType, UUID targetId, String reason, String description,
                            ReportStatus status, Instant createdAt) { }
    public record NotificationDto(UUID id, String title, String message, String type, String relatedEntityType,
                                 UUID relatedEntityId, boolean read, Instant createdAt) { }
}
