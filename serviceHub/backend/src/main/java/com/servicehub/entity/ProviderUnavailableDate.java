package com.servicehub.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"provider_id", "date"}))
@Getter @Setter
public class ProviderUnavailableDate extends AuditedEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    private User provider;

    @Column(nullable = false)
    private LocalDate date;

    @Column(length = 1000)
    private String reason;
}
