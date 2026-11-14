package com.servicehub.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "product_favorites", uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "product_id"}))
@Getter @Setter
public class ProductFavorite {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User user;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private SupplierProduct product;
    @Column(nullable = false) private Instant createdAt = Instant.now();
}
