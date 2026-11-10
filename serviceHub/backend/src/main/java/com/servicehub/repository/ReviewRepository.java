package com.servicehub.repository;

import com.servicehub.entity.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface ReviewRepository extends JpaRepository<Review, UUID> {
    boolean existsByBookingId(UUID bookingId);
    List<Review> findByServiceId(UUID serviceId);
    List<Review> findByProviderId(UUID providerId);
}
