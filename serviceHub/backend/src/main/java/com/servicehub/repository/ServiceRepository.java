package com.servicehub.repository;

import com.servicehub.entity.ServiceListing;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ServiceRepository extends JpaRepository<ServiceListing, UUID> {
    Page<ServiceListing> findByActiveTrueAndProviderBlockedFalseAndTitleContainingIgnoreCaseAndCategoryContainingIgnoreCase(String title, String category, Pageable pageable);
    Page<ServiceListing> findByProviderIdAndActiveTrueAndProviderBlockedFalse(UUID providerId, Pageable pageable);
    Page<ServiceListing> findByProviderId(UUID providerId, Pageable pageable);
}
