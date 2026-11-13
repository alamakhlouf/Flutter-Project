package com.servicehub.controller;

import com.servicehub.dto.ApiDtos.*;
import com.servicehub.dto.DtoMapper;
import com.servicehub.entity.*;
import com.servicehub.exception.ApiException;
import com.servicehub.service.MarketplaceService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.PageImpl;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api")
public class MarketplaceController {
    private final MarketplaceService market;
    public MarketplaceController(MarketplaceService market) { this.market=market; }
    private Pageable pageable(int page,int size) {
        if(page<0||size<1||size>100) throw ApiException.invalid("page must be non-negative and size must be between 1 and 100");
        return PageRequest.of(page,size);
    }

    @GetMapping("/services") public Page<ServiceDto> services(@RequestParam(defaultValue="") String search,
           @RequestParam(defaultValue="") String category,@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size) {
        return market.listServices(search,category,pageable(page,size));
    }
    @GetMapping("/services/my") public Page<ServiceDto> myServices(@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size) {
        return market.myServices(pageable(page,size));
    }
    @GetMapping("/services/{id}") public ServiceDto service(@PathVariable UUID id) { return market.service(id); }
    @PostMapping("/services") public ServiceDto createService(@Valid @RequestBody ServiceRequest req) { return market.createService(req); }
    @PutMapping("/services/{id}") public ServiceDto updateService(@PathVariable UUID id,@Valid @RequestBody ServiceRequest req) { return market.updateService(id,req); }
    @PatchMapping("/services/{id}/active") public ServiceDto activeService(@PathVariable UUID id,@Valid @RequestBody ActiveUpdate req) { return market.serviceActive(id,req); }
    @DeleteMapping("/services/{id}") public void deleteService(@PathVariable UUID id) { market.deleteService(id); }
    @GetMapping("/providers/{providerId}/services") public Page<ServiceDto> providerServices(@PathVariable UUID providerId,@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size) {
        return market.providerServices(providerId,pageable(page,size));
    }

    @GetMapping("/inventory") public List<InventoryDto> inventory() { return market.myInventory(); }
    @GetMapping("/inventory/{id}") public InventoryDto inventory(@PathVariable UUID id) { return market.inventoryItem(id); }
    @PostMapping("/inventory") public InventoryDto createInventory(@Valid @RequestBody InventoryRequest req) { return market.createInventory(req); }
    @PutMapping("/inventory/{id}") public InventoryDto updateInventory(@PathVariable UUID id,@Valid @RequestBody InventoryRequest req) { return market.updateInventory(id,req); }
    @PatchMapping("/inventory/{id}/quantity") public InventoryDto quantity(@PathVariable UUID id,@Valid @RequestBody QuantityUpdate req) { return market.changeQuantity(id,req); }
    @DeleteMapping("/inventory/{id}") public void deleteInventory(@PathVariable UUID id) { market.deleteInventory(id); }

    @PostMapping("/bookings") public BookingDto createBooking(@Valid @RequestBody BookingRequest req) { return market.createBooking(req); }
    @GetMapping("/bookings/my") public List<BookingDto> myBookings() { return market.myBookings(); }
    @GetMapping("/bookings/{id}") public BookingDto booking(@PathVariable UUID id) { return market.booking(id); }
    @PatchMapping("/bookings/{id}/status") public BookingDto bookingStatus(@PathVariable UUID id,@Valid @RequestBody BookingStatusUpdate req) { return market.bookingStatus(id,req.status()); }
    @PatchMapping("/bookings/{id}/cancel") public BookingDto cancelBooking(@PathVariable UUID id) { return market.cancelBooking(id); }

    @GetMapping("/suppliers") public List<UserDto> suppliers() { return market.suppliers(); }
    @GetMapping("/suppliers/{id}") public UserDto supplier(@PathVariable UUID id) { return market.supplier(id); }
    @GetMapping("/products/my") public Page<ProductDto> myProducts(@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size) {
        return market.myProducts(pageable(page,size));
    }
    @GetMapping("/products") public Page<ProductDto> products(@RequestParam(defaultValue="") String search,@RequestParam(defaultValue="") String category,
           @RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size) { return market.listProducts(search,category,pageable(page,size)); }
    @GetMapping("/products/{id}") public ProductDto product(@PathVariable UUID id) { return market.product(id); }
    @PostMapping("/products") public ProductDto createProduct(@Valid @RequestBody ProductRequest req) { return market.createProduct(req); }
    @PutMapping("/products/{id}") public ProductDto updateProduct(@PathVariable UUID id,@Valid @RequestBody ProductRequest req) { return market.updateProduct(id,req); }
    @PatchMapping("/products/{id}/availability") public ProductDto productAvailability(@PathVariable UUID id,@Valid @RequestBody ProductAvailability req) { return market.productAvailability(id,req); }
    @DeleteMapping("/products/{id}") public void deleteProduct(@PathVariable UUID id) { market.deleteProduct(id); }
    @PostMapping("/orders") public OrderDto createOrder(@Valid @RequestBody OrderRequest req) { return market.createOrder(req); }
    @GetMapping("/orders/my") public List<OrderDto> myOrders() { return market.myOrders(); }
    @GetMapping("/orders/{id}") public OrderDto order(@PathVariable UUID id) { return market.order(id); }
    @PatchMapping("/orders/{id}/status") public OrderDto orderStatus(@PathVariable UUID id,@Valid @RequestBody OrderStatusUpdate req) { return market.orderStatus(id,req.status()); }
    @PatchMapping("/orders/{id}/cancel") public OrderDto cancelOrder(@PathVariable UUID id) { return market.cancelOrder(id); }

    @GetMapping("/workshops") public Page<WorkshopDto> workshops(@RequestParam(required=false) String search,@RequestParam(required=false) String category,
            @RequestParam(required=false) Instant date,@RequestParam(required=false) Boolean availability,
            @RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size) {
        Pageable pageable=pageable(page,size);
        List<WorkshopDto> filtered=market.publicWorkshops().stream()
                .filter(w->search==null||w.title().toLowerCase().contains(search.toLowerCase()))
                .filter(w->category==null||w.category().equalsIgnoreCase(category))
                .filter(w->date==null||!w.startDateTime().isBefore(date))
                .filter(w->availability==null||!availability||w.participantCount()<w.capacity())
                .toList();
        int from=(int)Math.min(pageable.getOffset(),filtered.size()), to=Math.min(from+pageable.getPageSize(),filtered.size());
        return new PageImpl<>(filtered.subList(from,to),pageable,filtered.size());
    }
    @GetMapping("/workshops/{id}") public WorkshopDto workshop(@PathVariable UUID id) { return market.workshop(id); }
    @PostMapping("/workshops") public WorkshopDto createWorkshop(@Valid @RequestBody WorkshopRequest req) { return market.createWorkshop(req); }
    @PutMapping("/workshops/{id}") public WorkshopDto updateWorkshop(@PathVariable UUID id,@Valid @RequestBody WorkshopRequest req) { return market.updateWorkshop(id,req); }
    @PatchMapping("/workshops/{id}/publish") public WorkshopDto publishWorkshop(@PathVariable UUID id) { return market.publishWorkshop(id); }
    @PatchMapping("/workshops/{id}/cancel") public WorkshopDto cancelWorkshop(@PathVariable UUID id) { return market.cancelWorkshop(id); }
    @GetMapping("/workshops/my/organized") public List<WorkshopDto> organized() { return market.organized(); }
    @GetMapping("/workshops/my/registrations") public List<RegistrationDto> myRegistrations() { return market.myRegistrations(); }
    @GetMapping("/workshops/{id}/participants") public List<UserDto> participants(@PathVariable UUID id) { return market.participants(id); }
    @PostMapping("/workshops/{id}/registrations") public RegistrationDto register(@PathVariable UUID id) { return market.register(id); }
    @DeleteMapping("/workshops/{id}/registrations/me") public void cancelRegistration(@PathVariable UUID id) { market.cancelRegistration(id); }

    @PostMapping("/reviews") public ReviewDto review(@Valid @RequestBody ReviewRequest req) { return market.createReview(req); }
    @GetMapping("/services/{serviceId}/reviews") public List<ReviewDto> serviceReviews(@PathVariable UUID serviceId) { return market.serviceReviews(serviceId); }
    @GetMapping("/providers/{providerId}/reviews") public List<ReviewDto> providerReviews(@PathVariable UUID providerId) { return market.providerReviews(providerId); }
    @PostMapping("/reports") public ReportDto report(@Valid @RequestBody ReportRequest req) { return market.createReport(req); }
    @GetMapping("/reports/my") public List<ReportDto> myReports() { return market.myReports(); }
    @GetMapping("/admin/reports") public List<ReportDto> adminReports() { return market.adminReports(); }
    @GetMapping("/admin/reports/{id}") public ReportDto adminReport(@PathVariable UUID id) { return market.adminReport(id); }
    @PatchMapping("/admin/reports/{id}/status") public ReportDto reportStatus(@PathVariable UUID id,@Valid @RequestBody ReportStatusUpdate req) { return market.adminReportStatus(id,req.status()); }
    @PatchMapping("/admin/users/{id}/block") public UserDto blockUser(@PathVariable UUID id) { return market.adminBlockUser(id); }
    @DeleteMapping("/admin/services/{id}") public void deleteAdminService(@PathVariable UUID id) { market.adminDeleteService(id); }
    @GetMapping("/notifications") public List<NotificationDto> notifications() { return market.myNotifications(); }
    @PatchMapping("/notifications/{id}/read") public NotificationDto readNotification(@PathVariable UUID id) { return market.readNotification(id); }
    @PatchMapping("/notifications/read-all") public void readAll() { market.readAllNotifications(); }
}
