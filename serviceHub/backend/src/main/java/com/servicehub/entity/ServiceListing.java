package com.servicehub.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "services")
@Getter @Setter
public class ServiceListing extends AuditedEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User provider;
    @NotBlank @Column(nullable = false) private String title;
    @Column(length = 4000) private String description;
    @NotBlank @Column(nullable = false) private String category;
    @DecimalMin("0.00") @Column(nullable = false, precision = 12, scale = 2) private BigDecimal price;
    @Column(columnDefinition = "LONGTEXT") private String imageUrl;
    @Column(nullable = false) private boolean active = true;
}
