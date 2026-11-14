package com.servicehub.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.DecimalMin;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.util.UUID;

@Entity @Getter @Setter
public class InventoryItem extends AuditedEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User provider;
    @NotBlank @Column(nullable = false) private String name;
    @Column(length = 2000) private String description;
    @Column(columnDefinition = "LONGTEXT") private String imageUrl;
    @Min(0) @Column(nullable = false) private int quantity;
    @NotBlank @Column(nullable = false) private String unit;
    @Min(0) private Integer lowStockThreshold;
    @Column(length = 100) private String catalogCategory;
    @DecimalMin("0.00") @Column(precision = 12, scale = 2) private BigDecimal catalogPrice;
}
