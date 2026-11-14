package com.servicehub.dto;

import com.servicehub.entity.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

public final class ApiDtos {
    private ApiDtos() { }
    public record RegisterRequest(@NotBlank String fullName, @Email @NotBlank String email, @NotBlank @Size(min = 8) String password,
                                  @NotNull Role role, String phone, String profileImageUrl) { }
    public record LoginRequest(@Email @NotBlank String email, @NotBlank String password) { }
    public record GoogleAuthRequest(@NotBlank String idToken, Role role) { }
    public record UserDto(UUID id, String fullName, String email, Role role, String phone, String profileImageUrl, boolean blocked) { }
    public record AuthResponse(String token, UserDto user) { }
    public record ProfileUpdate(@NotBlank String fullName, String phone, String profileImageUrl) { }
    public record ServiceRequest(@NotBlank String title, String description, @NotBlank String category,
                                 @NotNull @DecimalMin("0.00") BigDecimal price, String imageUrl) { }
    public record ActiveUpdate(@NotNull Boolean active) { }
    public record ServiceDto(UUID id, UUID providerId, String providerName, String title, String description,
                             String category, BigDecimal price, String imageUrl, boolean active, Instant createdAt, boolean favorite) { }
    public record InventoryRequest(@NotBlank String name, String description, @Min(0) int quantity,
                                   @NotBlank String unit, @Min(0) Integer lowStockThreshold) { }
    public record QuantityUpdate(@Min(0) int quantity) { }
    public record InventoryDto(UUID id, UUID providerId, String name, String description, int quantity, String unit,
                               Integer lowStockThreshold, String stockStatus, Instant updatedAt) { }
    public record BookingRequest(@NotNull UUID serviceId, @NotNull Instant preferredDateTime, String description) { }
    public record StatusUpdate(@NotNull Enum<?> status) { }
    public record BookingStatusUpdate(@NotNull BookingStatus status) { }
    public record OrderStatusUpdate(@NotNull OrderStatus status) { }
    public record BookingDto(UUID id, UUID customerId, String customerName, UUID providerId, UUID serviceId, String serviceTitle,
                             BigDecimal price, String description, Instant preferredDateTime, BookingStatus status, Instant createdAt) { }
    public record ProductRequest(@NotBlank String name, String description, @NotBlank String category,
                                 @NotNull @DecimalMin("0.00") BigDecimal price, @Size(max = 2048) String imageUrl,
                                 @Min(0) Integer quantityAvailable, boolean available) { }
    public record ProductAvailability(@NotNull Boolean available) { }
    public record ProductDto(UUID id, UUID supplierId, String supplierName, String name, String description,
                             String category, BigDecimal price, String imageUrl, Integer quantityAvailable, boolean available, boolean favorite) { }
    public record OrderLineRequest(@NotNull UUID productId, @Min(1) int quantity) { }
    public record OrderRequest(@NotEmpty List<@Valid OrderLineRequest> items) { }
    public record OrderItemDto(UUID id, UUID productId, String productName, BigDecimal unitPrice, int quantity, BigDecimal lineTotal) { }
    public record OrderDto(UUID id, UUID customerId, String customerName, UUID supplierId, String supplierName,
                           BigDecimal totalAmount, OrderStatus status, List<OrderItemDto> items, Instant createdAt) { }
    public record WorkshopRequest(@NotBlank String title, String description, @NotBlank String category, String coverImageUrl,
                                  @NotNull Instant startDateTime, @NotNull Instant endDateTime, @NotBlank String location,
                                  @Min(1) int capacity, @NotNull Instant registrationDeadline, @NotNull WorkshopType workshopType) { }
    public record WorkshopDto(UUID id, UUID organizerId, String organizerName, String title, String description,
                              String category, String coverImageUrl, Instant startDateTime, Instant endDateTime,
                              String location, int capacity, Instant registrationDeadline, WorkshopStatus status,
                              long participantCount, WorkshopType workshopType, String meetingUrl) { }
    public record RegistrationDto(UUID id, UUID workshopId, String workshopTitle, String workshopLocation,
                                  Instant workshopStartDateTime, String workshopStatus, String organizerName,
                                  UUID participantId, WorkshopRegistrationStatus status, Instant registeredAt,
                                  Instant cancelledAt, String workshopMeetingUrl, WorkshopType workshopType) { }
    public record ReviewRequest(@NotNull UUID bookingId, @Min(1) @Max(5) int rating, @Size(max = 2000) String comment) { }
    public record ReviewDto(UUID id, UUID bookingId, UUID customerId, UUID providerId, UUID serviceId, int rating,
                            String comment, Instant createdAt) { }
    public record ReportRequest(@NotBlank String targetType, @NotNull UUID targetId, @NotBlank String reason,
                                @Size(max = 2000) String description) { }
    public record ReportStatusUpdate(@NotNull ReportStatus status) { }
    public record ReportDto(UUID id, UUID reporterId, String reporterName, String targetType, UUID targetId,
                            String targetTitle, String reason, String description, ReportStatus status, Instant createdAt) { }
    public record NotificationDto(UUID id, String title, String message, String type, String relatedEntityType,
                                 UUID relatedEntityId, boolean read, Instant createdAt) { }
    public record DeviceTokenRequest(@NotBlank String token) { }

    // Availability & Calendar DTOs
    public record ProviderAvailabilityRequest(@NotNull DayOfWeek dayOfWeek, @NotNull LocalTime startTime, @NotNull LocalTime endTime, LocalTime breakStart, LocalTime breakEnd) { }
    public record ProviderAvailabilityDto(UUID id, UUID providerId, DayOfWeek dayOfWeek, LocalTime startTime, LocalTime endTime, LocalTime breakStart, LocalTime breakEnd) { }
    public record UnavailableDateRequest(@NotNull LocalDate date, @Size(max = 1000) String reason) { }
    public record UnavailableDateDto(UUID id, UUID providerId, LocalDate date, String reason, Instant createdAt) { }
    public record AvailableSlotDto(Instant startDateTime, Instant endDateTime) { }
    public record ProviderCalendarDto(LocalDate date, ProviderAvailabilityDto availability, UnavailableDateDto unavailableDate, List<BookingDto> bookings) { }
}
