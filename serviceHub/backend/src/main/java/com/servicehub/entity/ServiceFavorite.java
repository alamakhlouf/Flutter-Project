package com.servicehub.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "service_favorites", uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "service_id"}))
@Getter @Setter
public class ServiceFavorite {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "service_id", nullable = false)
    private ServiceListing service;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();
}
