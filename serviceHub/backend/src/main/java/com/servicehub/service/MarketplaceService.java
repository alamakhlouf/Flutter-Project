package com.servicehub.service;

import com.servicehub.dto.ApiDtos.*;
import com.servicehub.dto.DtoMapper;
import com.servicehub.entity.*;
import com.servicehub.exception.ApiException;
import com.servicehub.repository.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.*;
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
    private final ProviderAvailabilityRepository availabilityRepo;
    private final ProviderUnavailableDateRepository unavailableDateRepo;
    private final ProductFavoriteRepository favoriteRepository;
    private final ServiceFavoriteRepository serviceFavoriteRepository;
    private final UserDeviceTokenRepository deviceTokenRepository;
    private final FcmPushService fcmPushService;
    private final GoogleCalendarService googleCalendarService;
    private final CurrentUser current;

    public MarketplaceService(ServiceRepository services, InventoryRepository inventory, BookingRepository bookings,
                              ProductRepository products, LockingRepository productLocks, OrderRepository orders,
                              WorkshopRepository workshops, WorkshopLockRepository workshopLocks,
                              RegistrationRepository registrations, ReviewRepository reviews, ReportRepository reports,
                              NotificationRepository notifications, UserRoleRepository users,
                              ProviderAvailabilityRepository availabilityRepo, ProviderUnavailableDateRepository unavailableDateRepo,
                              ProductFavoriteRepository favoriteRepository,
                              ServiceFavoriteRepository serviceFavoriteRepository,
                              UserDeviceTokenRepository deviceTokenRepository,
                              FcmPushService fcmPushService,
                              GoogleCalendarService googleCalendarService,
                              CurrentUser current) {
        this.services=services; this.inventory=inventory; this.bookings=bookings; this.products=products;
        this.productLocks=productLocks; this.orders=orders; this.workshops=workshops; this.workshopLocks=workshopLocks;
        this.registrations=registrations; this.reviews=reviews; this.reports=reports; this.notifications=notifications;
        this.users=users; this.availabilityRepo=availabilityRepo; this.unavailableDateRepo=unavailableDateRepo;
        this.favoriteRepository = favoriteRepository;
        this.serviceFavoriteRepository = serviceFavoriteRepository;
        this.deviceTokenRepository = deviceTokenRepository;
        this.fcmPushService = fcmPushService;
        this.googleCalendarService = googleCalendarService; this.current=current;
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
        fcmPushService.sendPushNotification(recipient, title, message, type, entityType, entityId);
    }

    private boolean isFavorite(User user, ServiceListing service) {
        if (user == null) return false;
        return serviceFavoriteRepository.existsByUserAndService(user, service);
    }

    public Page<ServiceDto> listServices(String search, String category, Pageable page) {
        User u = currentOrNull();
        return services.findByActiveTrueAndProviderBlockedFalseAndTitleContainingIgnoreCaseAndCategoryContainingIgnoreCase(
                search == null ? "" : search, category == null ? "" : category, page)
                .map(s -> DtoMapper.service(s, isFavorite(u, s)));
    }
    public ServiceDto service(UUID id) { 
        ServiceListing s = require(services.findById(id).filter(item -> item.isActive() && !item.getProvider().isBlocked()), "Service");
        return DtoMapper.service(s, isFavorite(currentOrNull(), s)); 
    }
    public Page<ServiceDto> providerServices(UUID id, Pageable page) { 
        User u = currentOrNull();
        return services.findByProviderIdAndActiveTrueAndProviderBlockedFalse(id, page)
                .map(s -> DtoMapper.service(s, isFavorite(u, s))); 
    }
    public Page<ServiceDto> myServices(Pageable page) {
        User u=actor(Role.PROVIDER);
        return services.findByProviderId(u.getId(), page).map(s -> DtoMapper.service(s, false));
    }
    @Transactional
    public ServiceDto favoriteService(UUID serviceId) {
        User customer = actor(Role.CUSTOMER);
        ServiceListing service = require(services.findById(serviceId).filter(s -> s.isActive() && !s.getProvider().isBlocked()), "Service");
        if (!serviceFavoriteRepository.existsByUserAndService(customer, service)) {
            ServiceFavorite fav = new ServiceFavorite();
            fav.setUser(customer);
            fav.setService(service);
            fav.setCreatedAt(Instant.now());
            serviceFavoriteRepository.save(fav);
        }
        return DtoMapper.service(service, true);
    }
    @Transactional
    public void unfavoriteService(UUID serviceId) {
        User customer = actor(Role.CUSTOMER);
        ServiceListing service = require(services.findById(serviceId), "Service");
        serviceFavoriteRepository.findByUserAndService(customer, service).ifPresent(serviceFavoriteRepository::delete);
    }
    public List<ServiceDto> myServiceFavorites() {
        User customer = actor(Role.CUSTOMER);
        return serviceFavoriteRepository.findByUserOrderByCreatedAtDesc(customer).stream()
                .map(f -> DtoMapper.service(f.getService(), true))
                .toList();
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
        User customer=actor(Role.CUSTOMER); ServiceListing s=require(services.findById(r.serviceId()).filter(x -> x.isActive() && !x.getProvider().isBlocked()),"Active service");
        if (!r.preferredDateTime().isAfter(Instant.now())) throw ApiException.invalid("Preferred date must be in the future");

        LocalDate bookingDate = r.preferredDateTime().atZone(ZoneOffset.UTC).toLocalDate();
        LocalTime bookingTime = r.preferredDateTime().atZone(ZoneOffset.UTC).toLocalTime();

        // 1. Check unavailable date
        if (unavailableDateRepo.existsByProviderIdAndDate(s.getProvider().getId(), bookingDate)) {
            throw ApiException.conflict("Provider is unavailable on this date");
        }

        // 2. Check working hours
        ProviderAvailability av = availabilityRepo.findByProviderIdAndDayOfWeek(s.getProvider().getId(), bookingDate.getDayOfWeek()).orElse(null);
        if (av != null) {
            if (bookingTime.isBefore(av.getStartTime()) || bookingTime.isAfter(av.getEndTime())) {
                throw ApiException.invalid("Booking time is outside provider working hours");
            }
            if (av.getBreakStart() != null && av.getBreakEnd() != null &&
                !bookingTime.isBefore(av.getBreakStart()) && bookingTime.isBefore(av.getBreakEnd())) {
                throw ApiException.invalid("Booking time falls during provider break period");
            }
        }

        // 3. Check double booking of accepted/in-progress slots
        boolean doubleBooked = bookings.findByProviderId(s.getProvider().getId()).stream()
            .filter(b -> b.getStatus() == BookingStatus.ACCEPTED || b.getStatus() == BookingStatus.IN_PROGRESS)
            .anyMatch(b -> b.getPreferredDateTime().equals(r.preferredDateTime()));
        if (doubleBooked) {
            throw ApiException.conflict("This time slot is already booked");
        }

        Booking b=new Booking(); b.setCustomer(customer); b.setProvider(s.getProvider()); b.setService(s);
        b.setServiceTitleSnapshot(s.getTitle()); b.setPriceSnapshot(s.getPrice()); b.setDescription(r.description());
        b.setPreferredDateTime(r.preferredDateTime()); bookings.save(b);
        notify(s.getProvider(),"New booking","A customer requested " + s.getTitle(),"BOOKING","Booking",b.getId());
        return DtoMapper.booking(b);
    }

    // Availability & Calendar methods
    public List<ProviderAvailabilityDto> myAvailability() {
        User u = actor(Role.PROVIDER);
        return availabilityRepo.findByProviderId(u.getId()).stream().map(DtoMapper::providerAvailability).toList();
    }

    @Transactional
    public List<ProviderAvailabilityDto> updateAvailability(List<ProviderAvailabilityRequest> reqs) {
        User u = actor(Role.PROVIDER);
        for (var r : reqs) {
            ProviderAvailability a = availabilityRepo.findByProviderIdAndDayOfWeek(u.getId(), r.dayOfWeek()).orElseGet(() -> {
                ProviderAvailability newItem = new ProviderAvailability();
                newItem.setProvider(u);
                newItem.setDayOfWeek(r.dayOfWeek());
                return newItem;
            });
            a.setStartTime(r.startTime());
            a.setEndTime(r.endTime());
            a.setBreakStart(r.breakStart());
            a.setBreakEnd(r.breakEnd());
            availabilityRepo.save(a);
        }
        return availabilityRepo.findByProviderId(u.getId()).stream().map(DtoMapper::providerAvailability).toList();
    }

    @Transactional
    public UnavailableDateDto createUnavailableDate(UnavailableDateRequest req) {
        User u = actor(Role.PROVIDER);
        if (unavailableDateRepo.existsByProviderIdAndDate(u.getId(), req.date())) {
            throw ApiException.conflict("Unavailable date already exists for this date");
        }
        ProviderUnavailableDate d = new ProviderUnavailableDate();
        d.setProvider(u);
        d.setDate(req.date());
        d.setReason(req.reason());
        unavailableDateRepo.save(d);
        return DtoMapper.unavailableDate(d);
    }

    @Transactional
    public void deleteUnavailableDate(UUID id) {
        User u = actor(Role.PROVIDER);
        ProviderUnavailableDate d = require(unavailableDateRepo.findById(id), "Unavailable date");
        owner(d.getProvider(), u);
        unavailableDateRepo.delete(d);
    }

    public List<AvailableSlotDto> availableSlots(UUID providerId, LocalDate date) {
        if (unavailableDateRepo.existsByProviderIdAndDate(providerId, date)) {
            return List.of();
        }
        ProviderAvailability av = availabilityRepo.findByProviderIdAndDayOfWeek(providerId, date.getDayOfWeek()).orElse(null);
        if (av == null) {
            return List.of();
        }
        Instant startOfDay = date.atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant endOfDay = date.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        List<Booking> providerBookings = bookings.findByProviderId(providerId).stream()
            .filter(b -> b.getStatus() == BookingStatus.ACCEPTED || b.getStatus() == BookingStatus.IN_PROGRESS)
            .filter(b -> !b.getPreferredDateTime().isBefore(startOfDay) && b.getPreferredDateTime().isBefore(endOfDay))
            .toList();

        List<AvailableSlotDto> slots = new ArrayList<>();
        LocalTime current = av.getStartTime();
        while (current.plusHours(1).compareTo(av.getEndTime()) <= 0) {
            LocalTime slotEnd = current.plusHours(1);
            boolean isBreak = av.getBreakStart() != null && av.getBreakEnd() != null &&
                !(slotEnd.compareTo(av.getBreakStart()) <= 0 || current.compareTo(av.getBreakEnd()) >= 0);

            if (!isBreak) {
                Instant slotStartInstant = LocalDateTime.of(date, current).toInstant(ZoneOffset.UTC);
                Instant slotEndInstant = LocalDateTime.of(date, slotEnd).toInstant(ZoneOffset.UTC);

                boolean booked = providerBookings.stream().anyMatch(b ->
                    b.getPreferredDateTime().equals(slotStartInstant) ||
                    (b.getPreferredDateTime().isAfter(slotStartInstant) && b.getPreferredDateTime().isBefore(slotEndInstant))
                );

                if (!booked && slotStartInstant.isAfter(Instant.now())) {
                    slots.add(new AvailableSlotDto(slotStartInstant, slotEndInstant));
                }
            }
            current = current.plusMinutes(30);
        }
        return slots;
    }

    public List<ProviderCalendarDto> providerCalendar(LocalDate startDate, LocalDate endDate) {
        User u = actor(Role.PROVIDER);
        List<ProviderAvailability> avs = availabilityRepo.findByProviderId(u.getId());
        List<ProviderUnavailableDate> unDates = unavailableDateRepo.findByProviderIdAndDateBetween(u.getId(), startDate, endDate);
        Instant startInstant = startDate.atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant endInstant = endDate.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        List<Booking> providerBookings = bookings.findByProviderId(u.getId()).stream()
            .filter(b -> !b.getPreferredDateTime().isBefore(startInstant) && b.getPreferredDateTime().isBefore(endInstant))
            .toList();

        List<ProviderCalendarDto> result = new ArrayList<>();
        LocalDate curr = startDate;
        while (!curr.isAfter(endDate)) {
            final LocalDate d = curr;
            ProviderAvailabilityDto avDto = avs.stream()
                .filter(a -> a.getDayOfWeek() == d.getDayOfWeek())
                .findFirst()
                .map(DtoMapper::providerAvailability)
                .orElse(null);

            UnavailableDateDto unDto = unDates.stream()
                .filter(un -> un.getDate().equals(d))
                .findFirst()
                .map(DtoMapper::unavailableDate)
                .orElse(null);

            Instant dayStart = d.atStartOfDay(ZoneOffset.UTC).toInstant();
            Instant dayEnd = d.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
            List<BookingDto> dayBookings = providerBookings.stream()
                .filter(b -> !b.getPreferredDateTime().isBefore(dayStart) && b.getPreferredDateTime().isBefore(dayEnd))
                .map(DtoMapper::booking)
                .toList();

            result.add(new ProviderCalendarDto(d, avDto, unDto, dayBookings));
            curr = curr.plusDays(1);
        }
        return result;
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

    public List<UserDto> suppliers() { return users.findByRoleAndBlockedFalse(Role.SUPPLIER).stream().map(DtoMapper::user).toList(); }
    public UserDto supplier(UUID id) {
        User u=require(users.findById(id).filter(x -> x.getRole()==Role.SUPPLIER && !x.isBlocked()),"Supplier"); return DtoMapper.user(u);
    }
    private User currentOrNull() {
        try {
            var auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated()) return null;
            return (User) users.findByEmailIgnoreCase(auth.getName()).orElse(null);
        } catch (Exception e) {
            return null;
        }
    }
    private boolean isFavorite(User user, SupplierProduct product) {
        if (user == null) return false;
        return favoriteRepository.existsByUserAndProduct(user, product);
    }

    public Page<ProductDto> listProducts(String search,String category,Pageable page) {
        User u = currentOrNull();
        return products.findAvailableProducts(
                search==null?"":search,category==null?"":category,page)
                .map(p -> DtoMapper.product(p, isFavorite(u, p)));
    }
    public Page<ProductDto> myProducts(Pageable page) {
        User supplier=actor(Role.SUPPLIER);
        return products.findBySupplierId(supplier.getId(),page).map(p -> DtoMapper.product(p, false));
    }
    public ProductDto product(UUID id) {
        SupplierProduct p = require(products.findById(id).filter(prod -> prod.isAvailable() && !prod.getSupplier().isBlocked()), "Product");
        return DtoMapper.product(p, isFavorite(currentOrNull(), p));
    }
    @Transactional
    public ProductDto favoriteProduct(UUID productId) {
        User customer = actor(Role.CUSTOMER);
        SupplierProduct product = require(products.findById(productId).filter(p -> p.isAvailable() && !p.getSupplier().isBlocked()), "Product");
        if (!favoriteRepository.existsByUserAndProduct(customer, product)) {
            ProductFavorite fav = new ProductFavorite();
            fav.setUser(customer);
            fav.setProduct(product);
            fav.setCreatedAt(Instant.now());
            favoriteRepository.save(fav);
        }
        return DtoMapper.product(product, true);
    }
    @Transactional
    public void unfavoriteProduct(UUID productId) {
        User customer = actor(Role.CUSTOMER);
        SupplierProduct product = require(products.findById(productId), "Product");
        favoriteRepository.findByUserAndProduct(customer, product).ifPresent(favoriteRepository::delete);
    }
    public List<ProductDto> myFavorites() {
        User customer = actor(Role.CUSTOMER);
        return favoriteRepository.findByUserOrderByCreatedAtDesc(customer).stream()
                .map(f -> DtoMapper.product(f.getProduct(), true))
                .toList();
    }
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
        User customer=current.get(); Map<UUID,Integer> quantities=new LinkedHashMap<>();
        for (OrderLineRequest line:r.items()) quantities.merge(line.productId(),line.quantity(),Integer::sum);
        List<SupplierProduct> selected=new ArrayList<>();
        quantities.keySet().stream().sorted(Comparator.comparing(UUID::toString))
                .forEach(id -> selected.add(require(productLocks.lockProduct(id),"Product")));
        if (selected.stream().anyMatch(p -> !p.isAvailable() || p.getSupplier().isBlocked())) {
            throw ApiException.conflict("One or more products belong to an unavailable or blocked supplier.");
        }
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
        order.setTotalAmount(total); orders.save(order); notify(order.getSupplier(),"New product order","A buyer submitted an order","ORDER","Order",order.getId());
        return DtoMapper.order(order);
    }
    public List<OrderDto> myOrders() {
        User u=current.get();
        return orders.findByCustomerIdOrSupplierId(u.getId(),u.getId()).stream().map(DtoMapper::order).toList();
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
        ProductOrder o=require(orders.findById(id),"Order"); owner(o.getCustomer(),current.get());
        if (!orderTransition(o.getStatus(),OrderStatus.CANCELLED)) throw ApiException.invalid("Order cannot be cancelled in its current state");
        o.setStatus(OrderStatus.CANCELLED); restoreStock(o); return DtoMapper.order(o);
    }
    private void restoreStock(ProductOrder o) {
        o.getItems().stream().sorted(Comparator.comparing(i->i.getProduct().getId().toString())).forEach(item -> {
            SupplierProduct product=require(productLocks.lockProduct(item.getProduct().getId()),"Product");
            if (product.getQuantityAvailable()!=null)
                product.getQuantityAvailable();
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

    public List<WorkshopDto> publicWorkshops() {
        return workshops.findByStatusAndOrganizerBlockedFalse(WorkshopStatus.PUBLISHED).stream()
                .map(w -> workshopDto(w, false))
                .toList();
    }
    public WorkshopDto workshop(UUID id) {
        Workshop w=require(workshops.findById(id),"Workshop");
        if(w.getOrganizer().isBlocked()) throw ApiException.notFound("Workshop");
        if(w.getStatus()!=WorkshopStatus.PUBLISHED && !isOrganizer(w)) throw ApiException.notFound("Workshop");
        return workshopDto(w);
    }
    @Transactional public WorkshopDto createWorkshop(WorkshopRequest r) {
        User organizer = actor(Role.PROVIDER);
        Workshop w = new Workshop();
        w.setOrganizer(organizer);
        copyWorkshop(r, w);
        validateWorkshop(r);

        if (w.getWorkshopType() == WorkshopType.ONLINE) {
            var status = googleCalendarService.getStatus(organizer);
            if (status.get("connected") != Boolean.TRUE) {
                throw ApiException.invalid("Please connect your Google account before creating an online workshop with Google Meet.");
            }
            googleCalendarService.createMeetEvent(w, organizer);
        }

        workshops.save(w);
        return workshopDto(w, true);
    }
    @Transactional public WorkshopDto updateWorkshop(UUID id,WorkshopRequest r) {
        Workshop w=require(workshopLocks.lockWorkshop(id),"Workshop"); owner(w.getOrganizer(),actor(Role.PROVIDER));
        if(w.getStatus()==WorkshopStatus.CANCELLED||w.getStatus()==WorkshopStatus.COMPLETED) throw ApiException.invalid("Workshop can no longer be edited");
        if(registrations.countByWorkshopIdAndStatus(id,WorkshopRegistrationStatus.REGISTERED)>r.capacity())
            throw ApiException.invalid("Capacity cannot be lower than the current participant count");
        validateWorkshop(r); copyWorkshop(r,w); return workshopDto(w, true);
    }
    @Transactional public WorkshopDto publishWorkshop(UUID id) {
        Workshop w=require(workshops.findById(id),"Workshop"); owner(w.getOrganizer(),actor(Role.PROVIDER));
        if(w.getStatus()!=WorkshopStatus.DRAFT || !w.getStartDateTime().isAfter(Instant.now())) throw ApiException.invalid("Only future draft workshops can be published");
        w.setStatus(WorkshopStatus.PUBLISHED); return workshopDto(w, true);
    }
    @Transactional public WorkshopDto cancelWorkshop(UUID id) {
        Workshop w=require(workshops.findById(id),"Workshop"); owner(w.getOrganizer(),actor(Role.PROVIDER));
        if(w.getStatus()==WorkshopStatus.COMPLETED||w.getStatus()==WorkshopStatus.CANCELLED) throw ApiException.invalid("Workshop is already closed");
        googleCalendarService.deleteEvent(w, w.getOrganizer());
        w.setStatus(WorkshopStatus.CANCELLED);
        w.setMeetingUrl(null);
        w.setGoogleCalendarEventId(null);
        return workshopDto(w, true);
    }
    @Transactional public WorkshopDto generateMeeting(UUID id) {
        Workshop w = require(workshopLocks.lockWorkshop(id), "Workshop");
        owner(w.getOrganizer(), actor(Role.PROVIDER));
        if (w.getWorkshopType() != WorkshopType.ONLINE) {
            throw ApiException.invalid("Meeting generation is only available for online workshops");
        }
        if (w.getStatus() == WorkshopStatus.CANCELLED || w.getStatus() == WorkshopStatus.COMPLETED) {
            throw ApiException.invalid("Cannot generate meeting for cancelled or completed workshops");
        }
        googleCalendarService.createMeetEvent(w, w.getOrganizer());
        workshops.save(w);
        return workshopDto(w, true);
    }
    public List<WorkshopDto> organized() {
        User u=actor(Role.PROVIDER);
        return workshops.findByOrganizerId(u.getId()).stream().map(w -> workshopDto(w, true)).toList();
    }
    @Transactional(readOnly = true)
    public List<RegistrationDto> myRegistrations() {
        return registrations.findByParticipantId(current.get().getId()).stream().map(r -> {
            boolean includeMeeting = r.getStatus() == WorkshopRegistrationStatus.REGISTERED;
            String meetingUrl = includeMeeting ? r.getWorkshop().getMeetingUrl() : null;
            return DtoMapper.registration(r, meetingUrl);
        }).toList();
    }
    public List<UserDto> participants(UUID id) {
        Workshop w=require(workshops.findById(id),"Workshop"); owner(w.getOrganizer(),actor(Role.PROVIDER));
        return registrations.findByWorkshopIdAndStatus(id,WorkshopRegistrationStatus.REGISTERED).stream().map(x->DtoMapper.user(x.getParticipant())).toList();
    }
    @Transactional public RegistrationDto register(UUID id) {
        Workshop w=require(workshopLocks.lockWorkshop(id),"Workshop"); User u=actor(Role.CUSTOMER,Role.PROVIDER);
        if(w.getOrganizer().isBlocked()) throw ApiException.invalid("Workshop organizer is unavailable");
        if(w.getStatus()!=WorkshopStatus.PUBLISHED) throw ApiException.invalid("Workshop is not open for registration");
        if(w.getOrganizer().getId().equals(u.getId())) throw ApiException.invalid("Organizers cannot register for their own workshop");
        if(!Instant.now().isBefore(w.getRegistrationDeadline())) throw ApiException.invalid("Registration deadline has passed");
        WorkshopRegistration existing=registrations.findByWorkshopIdAndParticipantId(id,u.getId()).orElse(null);
        if(existing!=null && existing.getStatus()==WorkshopRegistrationStatus.REGISTERED) throw ApiException.conflict("Already registered");
        if(registrations.countByWorkshopIdAndStatus(id,WorkshopRegistrationStatus.REGISTERED)>=w.getCapacity()) throw ApiException.conflict("Workshop is full");
        if(existing==null) { existing=new WorkshopRegistration(); existing.setWorkshop(w); existing.setParticipant(u); }
        existing.setStatus(WorkshopRegistrationStatus.REGISTERED); existing.setRegisteredAt(Instant.now()); existing.setCancelledAt(null);
        RegistrationDto regDto = DtoMapper.registration(registrations.save(existing), w.getMeetingUrl());
        return regDto;
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
    private boolean hasMeetingAccess(Workshop w) {
        var auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) return false;
        String email = auth.getName();
        if (w.getOrganizer().getEmail().equals(email)) return true;
        User u = (User) users.findByEmailIgnoreCase(email).orElse(null);
        if (u == null) return false;
        return registrations.findByWorkshopIdAndParticipantId(w.getId(), u.getId())
                .map(r -> r.getStatus() == WorkshopRegistrationStatus.REGISTERED)
                .orElse(false);
    }
    private WorkshopDto workshopDto(Workshop w, boolean includeMeeting) {
        String meetingUrl = includeMeeting ? w.getMeetingUrl() : null;
        return DtoMapper.workshop(w, registrations.countByWorkshopIdAndStatus(w.getId(), WorkshopRegistrationStatus.REGISTERED), meetingUrl);
    }
    private WorkshopDto workshopDto(Workshop w) {
        return workshopDto(w, hasMeetingAccess(w));
    }
    private void validateWorkshop(WorkshopRequest r) {
        if(!r.startDateTime().isAfter(Instant.now())||!r.endDateTime().isAfter(r.startDateTime())) throw ApiException.invalid("Workshop dates are invalid");
        if(!r.registrationDeadline().isAfter(Instant.now())||!r.registrationDeadline().isBefore(r.startDateTime()))
            throw ApiException.invalid("Registration deadline must be in the future and before workshop start");
    }
    private void copyWorkshop(WorkshopRequest r,Workshop w) {
        w.setTitle(r.title().trim());w.setDescription(r.description());w.setCategory(r.category().trim());w.setCoverImageUrl(r.coverImageUrl());
        w.setStartDateTime(r.startDateTime());w.setEndDateTime(r.endDateTime());w.setLocation(r.location().trim());w.setCapacity(r.capacity());w.setRegistrationDeadline(r.registrationDeadline());
        w.setWorkshopType(r.workshopType() != null ? r.workshopType() : WorkshopType.IN_PERSON);
        if (w.getWorkshopType() == WorkshopType.IN_PERSON) {
            w.setMeetingUrl(null);
            w.setGoogleCalendarEventId(null);
        }
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

    private String resolveTargetTitle(String targetType, UUID targetId) {
        if (targetType == null || targetId == null) return null;
        String type = targetType.toUpperCase();
        try {
            if ("SERVICE".equals(type)) {
                return services.findById(targetId).map(ServiceListing::getTitle).orElse(null);
            } else if ("USER".equals(type) || "PROFILE".equals(type) || "PROVIDER".equals(type) || "SUPPLIER".equals(type) || "CUSTOMER".equals(type)) {
                return users.findById(targetId).map(User::getFullName).orElse(null);
            } else if ("WORKSHOP".equals(type)) {
                return workshops.findById(targetId).map(Workshop::getTitle).orElse(null);
            } else if ("PRODUCT".equals(type)) {
                return products.findById(targetId).map(SupplierProduct::getName).orElse(null);
            }
        } catch (Exception ignored) { }
        return null;
    }

    @Transactional public ReportDto createReport(ReportRequest r) {
        Report report=new Report();report.setReporter(current.get());report.setTargetType(r.targetType().trim().toUpperCase());
        report.setTargetId(r.targetId());report.setReason(r.reason().trim());report.setDescription(r.description());
        Report saved = reports.save(report);
        return DtoMapper.report(saved, resolveTargetTitle(saved.getTargetType(), saved.getTargetId()));
    }
    public List<ReportDto> myReports() { return reports.findByReporterId(current.get().getId()).stream().map(r -> DtoMapper.report(r, resolveTargetTitle(r.getTargetType(), r.getTargetId()))).toList(); }
    public List<ReportDto> adminReports(String statusStr) {
        actor(Role.ADMIN);
        List<Report> list;
        if (statusStr != null && !statusStr.isBlank() && !"ALL".equalsIgnoreCase(statusStr)) {
            if ("PENDING".equalsIgnoreCase(statusStr) || "OPEN".equalsIgnoreCase(statusStr)) {
                list = reports.findAll().stream()
                    .filter(r -> r.getStatus() == ReportStatus.OPEN || r.getStatus() == ReportStatus.UNDER_REVIEW)
                    .toList();
            } else {
                try {
                    ReportStatus status = ReportStatus.valueOf(statusStr.toUpperCase());
                    list = reports.findByStatus(status);
                } catch (Exception e) {
                    list = reports.findAll();
                }
            }
        } else {
            list = reports.findAll();
        }
        return list.stream().map(r -> DtoMapper.report(r, resolveTargetTitle(r.getTargetType(), r.getTargetId()))).toList();
    }
    public ReportDto adminReport(UUID id) { actor(Role.ADMIN); Report r = require(reports.findById(id),"Report"); return DtoMapper.report(r, resolveTargetTitle(r.getTargetType(), r.getTargetId())); }
    @Transactional public ReportDto adminReportStatus(UUID id,ReportStatus status) {
        actor(Role.ADMIN); Report r=require(reports.findById(id),"Report");r.setStatus(status);return DtoMapper.report(r, resolveTargetTitle(r.getTargetType(), r.getTargetId()));
    }

    @Transactional public UserDto adminBlockUser(UUID userId) {
        actor(Role.ADMIN);
        User u = require(users.findById(userId), "User");
        u.setBlocked(true);
        return DtoMapper.user(u);
    }

    @Transactional public void adminDeleteService(UUID serviceId) {
        actor(Role.ADMIN);
        ServiceListing s = require(services.findById(serviceId), "Service");
        s.setActive(false);
    }

    public List<NotificationDto> myNotifications() {
        return notifications.findByRecipientIdOrderByCreatedAtDesc(current.get().getId()).stream().map(DtoMapper::notification).toList();
    }
    public long unreadNotificationCount() {
        return notifications.countByRecipientIdAndReadFalse(current.get().getId());
    }
    @Transactional public NotificationDto readNotification(UUID id) {
        Notification n=require(notifications.findById(id),"Notification");owner(n.getRecipient(),current.get());n.setRead(true);return DtoMapper.notification(n);
    }
    @Transactional public void readAllNotifications() {
        notifications.findByRecipientIdOrderByCreatedAtDesc(current.get().getId()).forEach(n->n.setRead(true));
    }
    @Transactional public void registerDeviceToken(String tokenStr) {
        if (tokenStr == null || tokenStr.isBlank()) return;
        User user = current.get();
        String cleanToken = tokenStr.trim();
        UserDeviceToken token = deviceTokenRepository.findByToken(cleanToken)
                .orElseGet(() -> {
                    UserDeviceToken t = new UserDeviceToken();
                    t.setToken(cleanToken);
                    return t;
                });
        token.setUser(user);
        token.setUpdatedAt(Instant.now());
        deviceTokenRepository.save(token);
    }
    @Transactional public void unregisterDeviceToken(String tokenStr) {
        if (tokenStr == null || tokenStr.isBlank()) return;
        User user = current.get();
        deviceTokenRepository.deleteByUserAndToken(user, tokenStr.trim());
    }
}
