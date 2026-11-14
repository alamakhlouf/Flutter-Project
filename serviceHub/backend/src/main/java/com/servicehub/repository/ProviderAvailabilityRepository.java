package com.servicehub.repository;

import com.servicehub.entity.ProviderAvailability;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.DayOfWeek;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProviderAvailabilityRepository extends JpaRepository<ProviderAvailability, UUID> {
    List<ProviderAvailability> findByProviderId(UUID providerId);
    Optional<ProviderAvailability> findByProviderIdAndDayOfWeek(UUID providerId, DayOfWeek dayOfWeek);
}
