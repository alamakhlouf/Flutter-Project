package com.servicehub.repository;

import com.servicehub.entity.ProviderUnavailableDate;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface ProviderUnavailableDateRepository extends JpaRepository<ProviderUnavailableDate, UUID> {
    List<ProviderUnavailableDate> findByProviderId(UUID providerId);
    List<ProviderUnavailableDate> findByProviderIdAndDateBetween(UUID providerId, LocalDate startDate, LocalDate endDate);
    boolean existsByProviderIdAndDate(UUID providerId, LocalDate date);
}
