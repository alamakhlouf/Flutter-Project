package com.servicehub.repository;

import com.servicehub.entity.Booking;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface BookingRepository extends JpaRepository<Booking, UUID> {
    List<Booking> findByCustomerIdOrProviderId(UUID customerId, UUID providerId);
    List<Booking> findByProviderId(UUID providerId);
    List<Booking> findByCustomerId(UUID customerId);
}
