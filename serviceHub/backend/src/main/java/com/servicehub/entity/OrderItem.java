package com.servicehub.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.util.UUID;

@Entity @Getter @Setter
public class OrderItem {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private ProductOrder order;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private SupplierProduct product;
    @Column(nullable = false) private String productNameSnapshot;
    @Column(nullable = false, precision = 12, scale = 2) private BigDecimal unitPriceSnapshot;
    @Column(nullable = false) private int quantity;
    @Column(nullable = false, precision = 12, scale = 2) private BigDecimal lineTotal;
}
