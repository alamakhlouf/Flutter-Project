package com.servicehub.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.UUID;

@Entity @Getter @Setter
public class Notification {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User recipient;
    @Column(nullable = false) private String title;
    @Column(nullable = false, length = 2000) private String message;
    @Column(nullable = false) private String type;
    private String relatedEntityType;
    private UUID relatedEntityId;
    @Column(name = "is_read", nullable = false) private boolean read;
    @Column(nullable = false) private Instant createdAt = Instant.now();
}
