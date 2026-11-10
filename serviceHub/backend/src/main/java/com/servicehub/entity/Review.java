package com.servicehub.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Getter;
import lombok.Setter;
import java.util.UUID;

@Entity @Table(uniqueConstraints = @UniqueConstraint(columnNames = "booking_id")) @Getter @Setter
public class Review extends AuditedEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @OneToOne(optional = false, fetch = FetchType.LAZY) private Booking booking;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User customer;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User provider;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private ServiceListing service;
    @Min(1) @Max(5) @Column(nullable = false) private int rating;
    @Column(length = 2000) private String comment;
}
