package com.servicehub.repository;

import com.servicehub.entity.ProviderGoogleToken;
import com.servicehub.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface ProviderGoogleTokenRepository extends JpaRepository<ProviderGoogleToken, UUID> {
    Optional<ProviderGoogleToken> findByProviderId(UUID providerId);
    Optional<ProviderGoogleToken> findByProvider(User provider);
}
