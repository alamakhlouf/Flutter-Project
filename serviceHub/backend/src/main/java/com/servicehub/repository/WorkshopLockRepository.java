package com.servicehub.repository;

import com.servicehub.entity.Workshop;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;
import java.util.Optional;
import java.util.UUID;

public interface WorkshopLockRepository extends Repository<Workshop, UUID> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select w from Workshop w where w.id = :id")
    Optional<Workshop> lockWorkshop(@Param("id") UUID id);
}
