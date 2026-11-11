package com.servicehub.service;

import com.servicehub.dto.ApiDtos.*;
import com.servicehub.dto.DtoMapper;
import com.servicehub.entity.*;
import com.servicehub.exception.ApiException;
import com.servicehub.repository.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;
import java.util.function.Consumer;

@Service
@Transactional(readOnly = true)
public class MarketplaceService {
    private final ServiceRepository services;
    private final InventoryRepository inventory;
    private final BookingRepository bookings;
    private final ProductRepository products;
    private final LockingRepository productLocks;
    private final OrderRepository orders;
    private final WorkshopRepository workshops;
    private final WorkshopLockRepository workshopLocks;
    private final RegistrationRepository registrations;
    private final ReviewRepository reviews;
    private final ReportRepository reports;
    private final NotificationRepository notifications;
    private final UserRoleRepository users;
    private final CurrentUser current;

    public MarketplaceService(ServiceRepository services, InventoryRepository inventory, BookingRepository bookings,
                              ProductRepository products, LockingRepository productLocks, OrderRepository orders,
                              WorkshopRepository workshops, WorkshopLockRepository workshopLocks,
                              RegistrationRepository registrations, ReviewRepository reviews, ReportRepository reports,
                              NotificationRepository notifications, UserRoleRepository users, CurrentUser current) {
        this.services=services; this.inventory=inventory; this.bookings=bookings; this.products=products;
        this.productLocks=productLocks; this.orders=orders; this.workshops=workshops; this.workshopLocks=workshopLocks;
        this.registrations=registrations; this.reviews=reviews; this.reports=reports; this.notifications=notifications;
        this.users=users; this.current=current;
    }

    private User actor(Role... roles) {
        User u=current.get();
        if (Arrays.stream(roles).noneMatch(r -> r==u.getRole())) throw ApiException.forbidden();
        return u;
    }
    private <T> T require(Optional<T> value, String type) { return value.orElseThrow(() -> ApiException.notFound(type)); }
    private void owner(User owner, User actor) { if (!owner.getId().equals(actor.getId())) throw ApiException.forbidden(); }
    private void notify(User recipient, String title, String message, String type, String entityType, UUID entityId) {
        Notification n=new Notification(); n.setRecipient(recipient); n.setTitle(title); n.setMessage(message);
        n.setType(type); n.setRelatedEntityType(entityType); n.setRelatedEntityId(entityId); notifications.save(n);
    }

    public Page<ServiceDto> listServices(String search, String category, Pageable page) {
        return services.findByActiveTrueAndTitleContainingIgnoreCaseAndCategoryContainingIgnoreCase(
                search == null ? "" : search, category == null ? "" : category, page).map(DtoMapper::service);
    }
    public ServiceDto service(UUID id) { return DtoMapper.service(require(services.findById(id).filter(ServiceListing::isActive), "Service")); }
    public Page<ServiceDto> providerServices(UUID id, Pageable page) { return services.findByProviderIdAndActiveTrue(id, page).map(DtoMapper::service); }
    public Page<ServiceDto> myServices(Pageable page) {
        User u=actor(Role.PROVIDER);
        return services.findByProviderId(u.getId(), page).map(DtoMapper::service);
    }
    @Transactional public ServiceDto createService(ServiceRequest req) {
        User u=actor(Role.PROVIDER); ServiceListing s=new ServiceListing(); s.setProvider(u); copy(req,s); return DtoMapper.service(services.save(s));
    }
    @Transactional public ServiceDto updateService(UUID id, ServiceRequest req) {
        ServiceListing s=require(services.findById(id),"Service"); owner(s.getProvider(),actor(Role.PROVIDER)); copy(req,s); return DtoMapper.service(s);
    }
    @Transactional public ServiceDto serviceActive(UUID id, ActiveUpdate req) {
        ServiceListing s=require(services.findById(id),"Service"); owner(s.getProvider(),actor(Role.PROVIDER)); s.setActive(req.active()); return DtoMapper.service(s);
    }
    @Transactional public void deleteService(UUID id) {
        ServiceListing s=require(services.findById(id),"Service"); owner(s.getProvider(),actor(Role.PROVIDER)); s.setActive(false);
    }
    private void copy(ServiceRequest r, ServiceListing s) {
        s.setTitle(r.title().trim()); s.setDescription(r.description()); s.setCategory(r.category().trim()); s.setPrice(r.price()); s.setImageUrl(r.imageUrl());
    }

    public List<InventoryDto> myInventory() { User u=actor(Role.PROVIDER); return inventory.findByProviderId(u.getId()).stream().map(DtoMapper::inventory).toList(); }
    public InventoryDto inventoryItem(UUID id) {
        InventoryItem i=require(inventory.findById(id),"Inventory item"); owner(i.getProvider(),actor(Role.PROVIDER)); return DtoMapper.inventory(i);
    }
    @Transactional public InventoryDto createInventory(InventoryRequest r) {
        InventoryItem i=new InventoryItem(); i.setProvider(actor(Role.PROVIDER)); fillInventory(r,i); return DtoMapper.inventory(inventory.save(i));
    }
    @Transactional public InventoryDto updateInventory(UUID id, InventoryRequest r) {
        InventoryItem i=require(inventory.findById(id),"Inventory item"); owner(i.getProvider(),actor(Role.PROVIDER)); fillInventory(r,i); return DtoMapper.inventory(i);
    }
    @Transactional public InventoryDto changeQuantity(UUID id, QuantityUpdate r) {
        InventoryItem i=require(inventory.findById(id),"Inventory item"); owner(i.getProvider(),actor(Role.PROVIDER)); i.setQuantity(r.quantity()); return DtoMapper.inventory(i);
    }
    @Transactional public void deleteInventory(UUID id) {
        InventoryItem i=require(inventory.findById(id),"Inventory item"); owner(i.getProvider(),actor(Role.PROVIDER)); inventory.delete(i);
    }
    private void fillInventory(InventoryRequest r, InventoryItem i) {
        i.setName(r.name().trim()); i.setDescription(r.description()); i.setQuantity(r.quantity()); i.setUnit(r.unit().trim()); i.setLowStockThreshold(r.lowStockThreshold());
    }

    @Transactional public BookingDto createBooking(BookingRequest r) {
        User customer=actor(Role.CUSTOMER); ServiceListing s=require(services.findById(r.serviceId()).filter(ServiceListing::isActive),"Active service");
        if (!r.preferredDateTime().isAfter(Instant.now())) throw ApiException.invalid("Preferred date must be in the future");
        Booking b=new Booking(); b.setCustomer(customer); b.setProvider(s.getProvider()); b.setService(s);
        b.setServiceTitleSnapshot(s.getTitle()); b.setPriceSnapshot(s.getPrice()); b.setDescription(r.description());
        b.setPreferredDateTime(r.preferredDateTime()); bookings.save(b);
        notify(s.getProvider(),"New booking","A customer requested " + s.getTitle(),"BOOKING","Booking",b.getId());
        return DtoMapper.booking(b);
    }
    public List<BookingDto> myBookings() {
        User u=current.get();
        List<Booking> rows=u.getRole()==Role.PROVIDER?bookings.findByProviderId(u.getId()):u.getRole()==Role.CUSTOMER?bookings.findByCustomerId(u.getId()):List.of();
        if (u.getRole()!=Role.PROVIDER && u.getRole()!=Role.CUSTOMER) throw ApiException.forbidden();
        return rows.stream().map(DtoMapper::booking).toList();
    }
    public BookingDto booking(UUID id) {
        Booking b=require(bookings.findById(id),"Booking"); User u=current.get();
        if (!b.getCustomer().getId().equals(u.getId())&&!b.getProvider().getId().equals(u.getId())) throw ApiException.forbidden();
        return DtoMapper.booking(b);
    }
    @Transactional public BookingDto bookingStatus(UUID id, BookingStatus status) {
        Booking b=require(bookings.findById(id),"Booking"); owner(b.getProvider(),actor(Role.PROVIDER));
        if (!bookingTransition(b.getStatus(),status)) throw ApiException.invalid("Invalid booking status transition");
        b.setStatus(status);
        notify(b.getCustomer(),"Booking updated","Your booking is now " + status,"BOOKING","Booking",b.getId());
        return DtoMapper.booking(b);
    }
    @Transactional public BookingDto cancelBooking(UUID id) {
        Booking b=require(bookings.findById(id),"Booking"); owner(b.getCustomer(),actor(Role.CUSTOMER));
        if (!bookingTransition(b.getStatus(),BookingStatus.CANCELLED)) throw ApiException.invalid("Booking cannot be cancelled in its current state");
        b.setStatus(BookingStatus.CANCELLED); notify(b.getProvider(),"Booking cancelled","A customer cancelled a booking","BOOKING","Booking",b.getId());
        return DtoMapper.booking(b);
    }
    private boolean bookingTransition(BookingStatus from, BookingStatus to) {
        return switch(from) {
            case PENDING -> to==BookingStatus.ACCEPTED||to==BookingStatus.REJECTED||to==BookingStatus.CANCELLED;
            case ACCEPTED -> to==BookingStatus.IN_PROGRESS||to==BookingStatus.CANCELLED;
            case IN_PROGRESS -> to==BookingStatus.COMPLETED;
            default -> false;
        };
    }

    public List<UserDto> suppliers() { return users.findByRole(Role.SUPPLIER).stream().map(DtoMapper::user).toList(); }
    public UserDto supplier(UUID id) {
        User u=require(users.findById(id).filter(x -> x.getRole()==Role.SUPPLIER),"Supplier"); return DtoMapper.user(u);
    }
    public Page<ProductDto> listProducts(String search,String category,Pageable page) {
        return products.findAvailableProducts(
                search==null?"":search,category==null?"":category,page).map(DtoMapper::product);
    }
    public Page<ProductDto> myProducts(Pageable page) {
        User supplier=actor(Role.SUPPLIER);
        return products.findBySupplierId(supplier.getId(),page).map(DtoMapper::product);
    }
    public ProductDto product(UUID id) { return DtoMapper.product(require(products.findById(id).filter(SupplierProduct::isAvailable),"Product")); }
    @Transactional public ProductDto createProduct(ProductRequest r) {
        SupplierProduct p=new SupplierProduct(); p.setSupplier(actor(Role.SUPPLIER)); fillProduct(r,p); return DtoMapper.product(products.save(p));
    }
    @Transactional public ProductDto updateProduct(UUID id,ProductRequest r) {
        SupplierProduct p=require(products.findById(id),"Product"); owner(p.getSupplier(),actor(Role.SUPPLIER)); fillProduct(r,p); return DtoMapper.product(p);
    }
    @Transactional public ProductDto productAvailability(UUID id,ProductAvailability r) {
        SupplierProduct p=require(products.findById(id),"Product"); owner(p.getSupplier(),actor(Role.SUPPLIER)); p.setAvailable(r.available()); return DtoMapper.product(p);
    }
    @Transactional public void deleteProduct(UUID id) {
        SupplierProduct p=require(products.findById(id),"Product"); owner(p.getSupplier(),actor(Role.SUPPLIER)); p.setAvailable(false);
    }
    private void fillProduct(ProductRequest r,SupplierProduct p) {
        p.setName(r.name().trim());p.setDescription(r.description());p.setCategory(r.category().trim());p.setPrice(r.price());
        p.setImageUrl(r.imageUrl());p.setQuantityAvailable(r.quantityAvailable());p.setAvailable(r.available());
    }

    @Transactional public OrderDto createOrder(OrderRequest r) {
        User customer=actor(Role.CUSTOMER); Map<UUID,Integer> quantities=new LinkedHashMap<>();
        for (OrderLineRequest line:r.items()) quantities.merge(line.productId(),line.quantity(),Integer::sum);
        List<SupplierProduct> selected=new ArrayList<>();
        quantities.keySet().stream().sorted(Comparator.comparing(UUID::toString))
                .forEach(id -> selected.add(require(productLocks.lockProduct(id),"Product")));
        UUID supplierId=selected.get(0).getSupplier().getId();
        if (selected.stream().anyMatch(p->!p.getSupplier().getId().equals(supplierId))) throw ApiException.invalid("An order may contain products from one supplier only");
        ProductOrder order=new ProductOrder(); order.setCustomer(customer); order.setSupplier(selected.get(0).getSupplier());
        BigDecimal total=BigDecimal.ZERO;
        for (SupplierProduct p:selected) {
            int q=quantities.get(p.getId());
            if (!p.isAvailable() || (p.getQuantityAvailable()!=null && p.getQuantityAvailable()<q)) throw ApiException.conflict("Product is unavailable or has insufficient stock: " + p.getName());
            BigDecimal lineTotal=p.getPrice().multiply(BigDecimal.valueOf(q)); total=total.add(lineTotal);
            if (p.getQuantityAvailable()!=null) p.setQuantityAvailable(p.getQuantityAvailable()-q);
            OrderItem item=new OrderItem(); item.setOrder(order); item.setProduct(p); item.setProductNameSnapshot(p.getName());
            item.setUnitPriceSnapshot(p.getPrice()); item.setQuantity(q); item.setLineTotal(lineTotal); order.getItems().add(item);
        }
        order.setTotalAmount(total); orders.save(order); notify(order.getSupplier(),"New product order","A customer submitted an order","ORDER","Order",order.getId());
        return DtoMapper.order(order);
    }
    public List<OrderDto> myOrders() {
        User u=current.get(); List<ProductOrder> list=u.getRole()==Role.CUSTOMER?orders.findByCustomerId(u.getId()):u.getRole()==Role.SUPPLIER?orders.findBySupplierId(u.getId()):null;
        if (list==null) throw ApiException.forbidden(); return list.stream().map(DtoMapper::order).toList();
    }
    public OrderDto order(UUID id) {
        ProductOrder o=require(orders.findById(id),"Order"); User u=current.get();
        if (!o.getCustomer().getId().equals(u.getId())&&!o.getSupplier().getId().equals(u.getId())) throw ApiException.forbidden();
        return DtoMapper.order(o);
    }
    @Transactional public OrderDto orderStatus(UUID id,OrderStatus status) {
        ProductOrder o=require(orders.findById(id),"Order"); owner(o.getSupplier(),actor(Role.SUPPLIER));
        if (!orderTransition(o.getStatus(),status)) throw ApiException.invalid("Invalid order status transition");
        o.setStatus(status); if (status==OrderStatus.REJECTED) restoreStock(o);
        notify(o.getCustomer(),"Order updated","Your order is now " + status,"ORDER","Order",o.getId()); return DtoMapper.order(o);
    }
    @Transactional public OrderDto cancelOrder(UUID id) {
        ProductOrder o=require(orders.findById(id),"Order"); owner(o.getCustomer(),actor(Role.CUSTOMER));
        if (!orderTransition(o.getStatus(),OrderStatus.CANCELLED)) throw ApiException.invalid("Order cannot be cancelled in its current state");
        o.setStatus(OrderStatus.CANCELLED); restoreStock(o); return DtoMapper.order(o);
    }
    private void restoreStock(ProductOrder o) {
        o.getItems().stream().sorted(Comparator.comparing(i->i.getProduct().getId().toString())).forEach(item -> {
            SupplierProduct product=require(productLocks.lockProduct(item.getProduct().getId()),"Product");
            if (product.getQuantityAvailable()!=null)
                product.setQuantityAvailable(product.getQuantityAvailable()+item.getQuantity());
        });
    }
    private boolean orderTransition(OrderStatus from,OrderStatus to) {
        return switch(from) {
            case PENDING -> to==OrderStatus.ACCEPTED||to==OrderStatus.REJECTED||to==OrderStatus.CANCELLED;
            case ACCEPTED -> to==OrderStatus.PROCESSING||to==OrderStatus.CANCELLED;
            case PROCESSING -> to==OrderStatus.COMPLETED;
            default -> false;
        };
    }

    public List<WorkshopDto> publicWorkshops() { return workshops.findByStatus(WorkshopStatus.PUBLISHED).stream().map(w->workshopDto(w)).toList(); }
    public WorkshopDto workshop(UUID id) {
        Workshop w=require(workshops.findById(id),"Workshop"); if(w.getStatus()!=WorkshopStatus.PUBLISHED && !isOrganizer(w)) throw ApiException.notFound("Workshop");
        return workshopDto(w);
    }
    @Transactional public WorkshopDto createWorkshop(WorkshopRequest r) {
        Workshop w=new Workshop(); w.setOrganizer(actor(Role.PROVIDER)); copyWorkshop(r,w); validateWorkshop(r); workshops.save(w); return workshopDto(w);
    }
    @Transactional public WorkshopDto updateWorkshop(UUID id,WorkshopRequest r) {
        Workshop w=require(workshopLocks.lockWorkshop(id),"Workshop"); owner(w.getOrganizer(),actor(Role.PROVIDER));
        if(w.getStatus()==WorkshopStatus.CANCELLED||w.getStatus()==WorkshopStatus.COMPLETED) throw ApiException.invalid("Workshop can no longer be edited");
        if(registrations.countByWorkshopIdAndStatus(id,WorkshopRegistrationStatus.REGISTERED)>r.capacity())
            throw ApiException.invalid("Capacity cannot be lower than the current participant count");
        validateWorkshop(r); copyWorkshop(r,w); return workshopDto(w);
    }
    @Transactional public WorkshopDto publishWorkshop(UUID id) {
        Workshop w=require(workshops.findById(id),"Workshop"); owner(w.getOrganizer(),actor(Role.PROVIDER));
        if(w.getStatus()!=WorkshopStatus.DRAFT || !w.getStartDateTime().isAfter(Instant.now())) throw ApiException.invalid("Only future draft workshops can be published");
        w.setStatus(WorkshopStatus.PUBLISHED); return workshopDto(w);
    }
    @Transactional public WorkshopDto cancelWorkshop(UUID id) {
        Workshop w=require(workshops.findById(id),"Workshop"); owner(w.getOrganizer(),actor(Role.PROVIDER));
        if(w.getStatus()==WorkshopStatus.COMPLETED||w.getStatus()==WorkshopStatus.CANCELLED) throw ApiException.invalid("Workshop is already closed");
        w.setStatus(WorkshopStatus.CANCELLED); return workshopDto(w);
    }
    public List<WorkshopDto> organized() {
        User u=actor(Role.PROVIDER); return workshops.findByOrganizerId(u.getId()).stream().map(this::workshopDto).toList();
    }
    public List<RegistrationDto> myRegistrations() { return registrations.findByParticipantId(current.get().getId()).stream().map(DtoMapper::registration).toList(); }
    public List<UserDto> participants(UUID id) {
        Workshop w=require(workshops.findById(id),"Workshop"); owner(w.getOrganizer(),actor(Role.PROVIDER));
        return registrations.findByWorkshopIdAndStatus(id,WorkshopRegistrationStatus.REGISTERED).stream().map(x->DtoMapper.user(x.getParticipant())).toList();
    }
    @Transactional public RegistrationDto register(UUID id) {
        Workshop w=require(workshopLocks.lockWorkshop(id),"Workshop"); User u=actor(Role.CUSTOMER,Role.PROVIDER);
        if(w.getStatus()!=WorkshopStatus.PUBLISHED) throw ApiException.invalid("Workshop is not open for registration");
        if(w.getOrganizer().getId().equals(u.getId())) throw ApiException.invalid("Organizers cannot register for their own workshop");
        if(!Instant.now().isBefore(w.getRegistrationDeadline())) throw ApiException.invalid("Registration deadline has passed");
        WorkshopRegistration existing=registrations.findByWorkshopIdAndParticipantId(id,u.getId()).orElse(null);
        if(existing!=null && existing.getStatus()==WorkshopRegistrationStatus.REGISTERED) throw ApiException.conflict("Already registered");
        if(registrations.countByWorkshopIdAndStatus(id,WorkshopRegistrationStatus.REGISTERED)>=w.getCapacity()) throw ApiException.conflict("Workshop is full");
        if(existing==null) { existing=new WorkshopRegistration(); existing.setWorkshop(w); existing.setParticipant(u); }
        existing.setStatus(WorkshopRegistrationStatus.REGISTERED); existing.setRegisteredAt(Instant.now()); existing.setCancelledAt(null);
        return DtoMapper.registration(registrations.save(existing));
    }
    @Transactional public void cancelRegistration(UUID id) {
        User u=actor(Role.CUSTOMER,Role.PROVIDER); WorkshopRegistration r=require(registrations.findByWorkshopIdAndParticipantId(id,u.getId()),"Registration");
        if(r.getStatus()!=WorkshopRegistrationStatus.REGISTERED) throw ApiException.invalid("Registration is already cancelled");
        if(!Instant.now().isBefore(r.getWorkshop().getRegistrationDeadline())) throw ApiException.invalid("Cancellation deadline has passed");
        r.setStatus(WorkshopRegistrationStatus.CANCELLED); r.setCancelledAt(Instant.now());
    }
    private boolean isOrganizer(Workshop w) {
        var a=org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        return a!=null && a.getName().equals(w.getOrganizer().getEmail());
    }
    private WorkshopDto workshopDto(Workshop w) { return DtoMapper.workshop(w,registrations.countByWorkshopIdAndStatus(w.getId(),WorkshopRegistrationStatus.REGISTERED)); }
    private void validateWorkshop(WorkshopRequest r) {
        if(!r.startDateTime().isAfter(Instant.now())||!r.endDateTime().isAfter(r.startDateTime())) throw ApiException.invalid("Workshop dates are invalid");
        if(!r.registrationDeadline().isAfter(Instant.now())||!r.registrationDeadline().isBefore(r.startDateTime()))
            throw ApiException.invalid("Registration deadline must be in the future and before workshop start");
    }
    private void copyWorkshop(WorkshopRequest r,Workshop w) {
        w.setTitle(r.title().trim());w.setDescription(r.description());w.setCategory(r.category().trim());w.setCoverImageUrl(r.coverImageUrl());
        w.setStartDateTime(r.startDateTime());w.setEndDateTime(r.endDateTime());w.setLocation(r.location().trim());w.setCapacity(r.capacity());w.setRegistrationDeadline(r.registrationDeadline());
    }

    @Transactional public ReviewDto createReview(ReviewRequest r) {
        User u=actor(Role.CUSTOMER); Booking b=require(bookings.findById(r.bookingId()),"Booking");
        owner(b.getCustomer(),u);
        if(b.getStatus()!=BookingStatus.COMPLETED) throw ApiException.invalid("Only completed bookings can be reviewed");
        if(reviews.existsByBookingId(b.getId())) throw ApiException.conflict("This booking has already been reviewed");
        Review review=new Review();review.setBooking(b);review.setCustomer(u);review.setProvider(b.getProvider());review.setService(b.getService());
        review.setRating(r.rating());review.setComment(r.comment());return DtoMapper.review(reviews.save(review));
    }
    public List<ReviewDto> serviceReviews(UUID id) { return reviews.findByServiceId(id).stream().map(DtoMapper::review).toList(); }
    public List<ReviewDto> providerReviews(UUID id) { return reviews.findByProviderId(id).stream().map(DtoMapper::review).toList(); }
    @Transactional public ReportDto createReport(ReportRequest r) {
        Report report=new Report();report.setReporter(current.get());report.setTargetType(r.targetType().trim().toUpperCase());
        report.setTargetId(r.targetId());report.setReason(r.reason().trim());report.setDescription(r.description());return DtoMapper.report(reports.save(report));
    }
    public List<ReportDto> myReports() { return reports.findByReporterId(current.get().getId()).stream().map(DtoMapper::report).toList(); }
    public List<ReportDto> adminReports() { actor(Role.ADMIN); return reports.findAll().stream().map(DtoMapper::report).toList(); }
    public ReportDto adminReport(UUID id) { actor(Role.ADMIN); return DtoMapper.report(require(reports.findById(id),"Report")); }
    @Transactional public ReportDto adminReportStatus(UUID id,ReportStatus status) {
        actor(Role.ADMIN); Report r=require(reports.findById(id),"Report");r.setStatus(status);return DtoMapper.report(r);
    }
    public List<NotificationDto> myNotifications() {
        return notifications.findByRecipientIdOrderByCreatedAtDesc(current.get().getId()).stream().map(DtoMapper::notification).toList();
    }
    @Transactional public NotificationDto readNotification(UUID id) {
        Notification n=require(notifications.findById(id),"Notification");owner(n.getRecipient(),current.get());n.setRead(true);return DtoMapper.notification(n);
    }
    @Transactional public void readAllNotifications() {
        notifications.findByRecipientIdOrderByCreatedAtDesc(current.get().getId()).forEach(n->n.setRead(true));
    }
}
