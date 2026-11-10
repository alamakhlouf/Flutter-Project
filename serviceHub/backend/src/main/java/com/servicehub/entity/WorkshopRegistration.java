package com.servicehub.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.UUID;

@Entity @Table(uniqueConstraints = @UniqueConstraint(columnNames = {"workshop_id", "participant_id"}))
@Getter @Setter
public class WorkshopRegistration {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private Workshop workshop;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User participant;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private WorkshopRegistrationStatus status = WorkshopRegistrationStatus.REGISTERED;
    @Column(nullable = false) private Instant registeredAt;
    private Instant cancelledAt;
}
