package com.servicehub.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.util.UUID;

@Entity @Getter @Setter
public class SupplierProduct extends AuditedEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User supplier;
    @NotBlank @Column(nullable = false) private String name;
    @Column(length = 3000) private String description;
    @NotBlank @Column(nullable = false) private String category;
    @DecimalMin("0.00") @Column(nullable = false, precision = 12, scale = 2) private BigDecimal price;
    private String imageUrl;
    @Min(0) private Integer quantityAvailable;
    @Column(nullable = false) private boolean available = true;
}
