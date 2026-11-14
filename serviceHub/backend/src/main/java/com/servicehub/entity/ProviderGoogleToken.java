package com.servicehub.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "provider_google_tokens")
@Getter
@Setter
public class ProviderGoogleToken extends AuditedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "provider_id", unique = true, nullable = false)
    private User provider;

    @Column(length = 2048, nullable = false)
    private String accessToken;

    @Column(length = 2048)
    private String refreshToken;

    @Column(nullable = false)
    private Instant tokenExpiresAt;

    private String googleEmail;
}
