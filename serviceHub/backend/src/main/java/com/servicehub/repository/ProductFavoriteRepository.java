package com.servicehub.repository;

import com.servicehub.entity.ProductFavorite;
import com.servicehub.entity.SupplierProduct;
import com.servicehub.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProductFavoriteRepository extends JpaRepository<ProductFavorite, UUID> {
    List<ProductFavorite> findByUserOrderByCreatedAtDesc(User user);
    Optional<ProductFavorite> findByUserAndProduct(User user, SupplierProduct product);
    boolean existsByUserAndProduct(User user, SupplierProduct product);
    void deleteByUserAndProduct(User user, SupplierProduct product);
}
