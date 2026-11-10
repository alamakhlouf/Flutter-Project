package com.servicehub.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity @Getter @Setter
public class Booking extends AuditedEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User customer;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User provider;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private ServiceListing service;
    @Column(nullable = false) private String serviceTitleSnapshot;
    @Column(nullable = false, precision = 12, scale = 2) private BigDecimal priceSnapshot;
    @Column(length = 2000) private String description;
    @Column(nullable = false) private Instant preferredDateTime;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private BookingStatus status = BookingStatus.PENDING;
}
