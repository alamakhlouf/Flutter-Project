package com.servicehub.config;

import com.servicehub.entity.*;
import com.servicehub.repository.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Configuration
@Profile("local")
public class LocalSeedData {
    @Bean
    CommandLineRunner seedLocalData(UserRepository users, ServiceRepository services, InventoryRepository inventory,
                                    ProductRepository products, WorkshopRepository workshops, PasswordEncoder encoder,
                                    @Value("${app.seed.enabled:true}") boolean enabled) {
        return args -> {
            if (!enabled || users.count() > 0) return;
            User customer=user(users,encoder,"Local Customer","customer@servicehub.local",Role.CUSTOMER);
            User provider=user(users,encoder,"Local Provider","provider@servicehub.local",Role.PROVIDER);
            User supplier=user(users,encoder,"Local Supplier","supplier@servicehub.local",Role.SUPPLIER);
            user(users,encoder,"Local Administrator","admin@servicehub.local",Role.ADMIN);

            ServiceListing service=new ServiceListing(); service.setProvider(provider); service.setTitle("Home cleaning");
            service.setDescription("A sample home cleaning service."); service.setCategory("Home"); service.setPrice(new BigDecimal("45.00"));
            services.save(service);
            InventoryItem item=new InventoryItem(); item.setProvider(provider); item.setName("Cleaning solution");
            item.setDescription("Sample inventory item."); item.setQuantity(12); item.setUnit("bottles"); item.setLowStockThreshold(3);
            inventory.save(item);
            SupplierProduct product=new SupplierProduct(); product.setSupplier(supplier); product.setName("Microfiber cloth set");
            product.setDescription("Reusable cleaning cloths."); product.setCategory("Cleaning"); product.setPrice(new BigDecimal("9.50"));
            product.setQuantityAvailable(40); product.setAvailable(true); products.save(product);
            Workshop workshop=new Workshop(); workshop.setOrganizer(provider); workshop.setTitle("DIY home care");
            workshop.setDescription("A sample provider workshop."); workshop.setCategory("Home"); workshop.setLocation("ServiceHub studio");
            workshop.setCapacity(12); workshop.setStartDateTime(Instant.now().plus(14,ChronoUnit.DAYS));
            workshop.setEndDateTime(Instant.now().plus(14,ChronoUnit.DAYS).plus(2,ChronoUnit.HOURS));
            workshop.setRegistrationDeadline(Instant.now().plus(13,ChronoUnit.DAYS)); workshop.setStatus(WorkshopStatus.PUBLISHED); workshops.save(workshop);
        };
    }
    private User user(UserRepository users,PasswordEncoder encoder,String name,String email,Role role) {
        User u=new User(); u.setFullName(name); u.setEmail(email); u.setRole(role); u.setPasswordHash(encoder.encode("ServiceHub123!")); return users.save(u);
    }
}
