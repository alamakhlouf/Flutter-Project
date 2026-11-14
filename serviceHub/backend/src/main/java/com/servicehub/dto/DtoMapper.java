package com.servicehub.dto;

import com.servicehub.entity.*;
import java.util.List;

import static com.servicehub.dto.ApiDtos.*;

public final class DtoMapper {
    private DtoMapper() { }
    public static UserDto user(User u) { return new UserDto(u.getId(), u.getFullName(), u.getEmail(), u.getRole(), u.getPhone(), u.getProfileImageUrl(), u.isBlocked()); }
    public static ServiceDto service(ServiceListing s, boolean favorite) { 
        return new ServiceDto(s.getId(), s.getProvider().getId(), s.getProvider().getFullName(), s.getTitle(), s.getDescription(), s.getCategory(), s.getPrice(), s.getImageUrl(), s.isActive(), s.getCreatedAt(), favorite); 
    }
    public static ServiceDto service(ServiceListing s) { return service(s, false); }
    public static InventoryDto inventory(InventoryItem i) {
        String state = i.getQuantity() == 0 ? "OUT_OF_STOCK" : i.getLowStockThreshold() != null && i.getQuantity() <= i.getLowStockThreshold() ? "LOW_STOCK" : "IN_STOCK";
        return new InventoryDto(i.getId(), i.getProvider().getId(), i.getName(), i.getDescription(), i.getQuantity(), i.getUnit(), i.getImageUrl(), i.getLowStockThreshold(), state, i.getUpdatedAt(), i.getCatalogCategory(), i.getCatalogPrice());
    }
    public static BookingDto booking(Booking b) { return new BookingDto(b.getId(), b.getCustomer().getId(), b.getCustomer().getFullName(), b.getProvider().getId(), b.getService().getId(), b.getServiceTitleSnapshot(), b.getPriceSnapshot(), b.getDescription(), b.getPreferredDateTime(), b.getStatus(), b.getCreatedAt()); }
    public static ProductDto product(SupplierProduct p, boolean favorite) {
        return new ProductDto(p.getId(), p.getSupplier().getId(), p.getSupplier().getFullName(), p.getName(), p.getDescription(), p.getCategory(), p.getPrice(), p.getImageUrl(), p.getQuantityAvailable(), p.isAvailable(), favorite);
    }
    public static ProductDto product(SupplierProduct p) { return product(p, false); }
    public static OrderDto order(ProductOrder o) {
        List<OrderItemDto> lines = o.getItems().stream().map(i -> new OrderItemDto(i.getId(), i.getProduct().getId(), i.getProductNameSnapshot(), i.getUnitPriceSnapshot(), i.getQuantity(), i.getLineTotal())).toList();
        return new OrderDto(o.getId(), o.getCustomer().getId(), o.getCustomer().getFullName(), o.getSupplier().getId(), o.getSupplier().getFullName(), o.getTotalAmount(), o.getStatus(), lines, o.getCreatedAt());
    }
    public static WorkshopDto workshop(Workshop w, long count, String meetingUrl) {
        return new WorkshopDto(w.getId(), w.getOrganizer().getId(), w.getOrganizer().getFullName(), w.getTitle(), w.getDescription(), w.getCategory(), w.getCoverImageUrl(), w.getStartDateTime(), w.getEndDateTime(), w.getLocation(), w.getCapacity(), w.getRegistrationDeadline(), w.getStatus(), count, w.getWorkshopType(), meetingUrl);
    }
    public static RegistrationDto registration(WorkshopRegistration r, String meetingUrl) {
        return new RegistrationDto(r.getId(), r.getWorkshop().getId(), r.getWorkshop().getTitle(), r.getWorkshop().getLocation(), r.getWorkshop().getStartDateTime(), r.getWorkshop().getStatus().name(), r.getWorkshop().getOrganizer().getFullName(), r.getParticipant().getId(), r.getStatus(), r.getRegisteredAt(), r.getCancelledAt(), meetingUrl, r.getWorkshop().getWorkshopType());
    }
    public static ReviewDto review(Review r) { return new ReviewDto(r.getId(), r.getBooking().getId(), r.getCustomer().getId(), r.getProvider().getId(), r.getService().getId(), r.getRating(), r.getComment(), r.getCreatedAt()); }
    public static ReportDto report(Report r, String targetTitle) {
        String reporterName = r.getReporter() != null ? r.getReporter().getFullName() : null;
        return new ReportDto(r.getId(), r.getReporter().getId(), reporterName, r.getTargetType(), r.getTargetId(), targetTitle, r.getReason(), r.getDescription(), r.getStatus(), r.getCreatedAt());
    }
    public static ReportDto report(Report r) {
        return report(r, null);
    }
    public static NotificationDto notification(Notification n) { return new NotificationDto(n.getId(), n.getTitle(), n.getMessage(), n.getType(), n.getRelatedEntityType(), n.getRelatedEntityId(), n.isRead(), n.getCreatedAt()); }

    public static ProviderAvailabilityDto providerAvailability(ProviderAvailability a) {
        return new ProviderAvailabilityDto(a.getId(), a.getProvider().getId(), a.getDayOfWeek(), a.getStartTime(), a.getEndTime(), a.getBreakStart(), a.getBreakEnd());
    }
    public static UnavailableDateDto unavailableDate(ProviderUnavailableDate d) {
        return new UnavailableDateDto(d.getId(), d.getProvider().getId(), d.getDate(), d.getReason(), d.getCreatedAt());
    }
}
