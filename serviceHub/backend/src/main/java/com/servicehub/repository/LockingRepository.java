package com.servicehub.repository;

import com.servicehub.entity.SupplierProduct;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Optional;
import java.util.UUID;

public interface LockingRepository extends org.springframework.data.repository.Repository<SupplierProduct, UUID> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from SupplierProduct p where p.id = :id")
    Optional<SupplierProduct> lockProduct(@Param("id") UUID id);
}
