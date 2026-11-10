package com.servicehub.repository;

import com.servicehub.entity.Workshop;
import com.servicehub.entity.WorkshopStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface WorkshopRepository extends JpaRepository<Workshop, UUID> {
    List<Workshop> findByStatus(WorkshopStatus status);
    List<Workshop> findByOrganizerId(UUID organizerId);
}
