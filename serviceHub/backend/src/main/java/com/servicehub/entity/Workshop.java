package com.servicehub.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.UUID;

@Entity @Getter @Setter
public class Workshop extends AuditedEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User organizer;
    @NotBlank @Column(nullable = false) private String title;
    @Column(length = 4000) private String description;
    @NotBlank @Column(nullable = false) private String category;
    private String coverImageUrl;
    @Column(nullable = false) private Instant startDateTime;
    @Column(nullable = false) private Instant endDateTime;
    @NotBlank @Column(nullable = false) private String location;
    @Min(1) @Column(nullable = false) private int capacity;
    @Column(nullable = false) private Instant registrationDeadline;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private WorkshopStatus status = WorkshopStatus.DRAFT;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private WorkshopType workshopType = WorkshopType.IN_PERSON;
    @Column(length = 2048) private String meetingUrl;
    private String googleCalendarEventId;
}
