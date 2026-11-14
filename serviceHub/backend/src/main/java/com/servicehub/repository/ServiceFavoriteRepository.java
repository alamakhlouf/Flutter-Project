package com.servicehub.repository;

import com.servicehub.entity.ServiceFavorite;
import com.servicehub.entity.ServiceListing;
import com.servicehub.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ServiceFavoriteRepository extends JpaRepository<ServiceFavorite, UUID> {
    List<ServiceFavorite> findByUserOrderByCreatedAtDesc(User user);
    Optional<ServiceFavorite> findByUserAndService(User user, ServiceListing service);
    boolean existsByUserAndService(User user, ServiceListing service);
}
