package com.servicehub.repository;

import com.servicehub.entity.SupplierProduct;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.UUID;

public interface ProductRepository extends JpaRepository<SupplierProduct, UUID> {
    @Query("""
            select p from SupplierProduct p
            where p.available = true
              and (p.quantityAvailable is null or p.quantityAvailable > 0)
              and lower(p.name) like lower(concat('%', :name, '%'))
              and lower(p.category) like lower(concat('%', :category, '%'))
            """)
    Page<SupplierProduct> findAvailableProducts(
            @Param("name") String name,
            @Param("category") String category,
            Pageable pageable);

    Page<SupplierProduct> findBySupplierId(UUID supplierId, Pageable pageable);
}
