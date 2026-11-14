package com.servicehub.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "user_device_tokens", uniqueConstraints = @UniqueConstraint(columnNames = {"token"}))
@Getter @Setter
public class UserDeviceToken {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 1000)
    private String token;

    @Column(nullable = false)
    private Instant updatedAt = Instant.now();
}
