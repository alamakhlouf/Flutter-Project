package com.servicehub.repository;

import com.servicehub.entity.ProductOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface OrderRepository extends JpaRepository<ProductOrder, UUID> {
    List<ProductOrder> findByCustomerIdOrSupplierId(UUID customerId, UUID supplierId);
    List<ProductOrder> findByCustomerId(UUID customerId);
    List<ProductOrder> findBySupplierId(UUID supplierId);
}
