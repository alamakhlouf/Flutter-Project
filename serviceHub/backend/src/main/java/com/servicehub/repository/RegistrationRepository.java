package com.servicehub.repository;

import com.servicehub.entity.WorkshopRegistration;
import com.servicehub.entity.WorkshopRegistrationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RegistrationRepository extends JpaRepository<WorkshopRegistration, UUID> {
    Optional<WorkshopRegistration> findByWorkshopIdAndParticipantId(UUID workshopId, UUID participantId);
    List<WorkshopRegistration> findByParticipantId(UUID participantId);
    List<WorkshopRegistration> findByWorkshopIdAndStatus(UUID workshopId, WorkshopRegistrationStatus status);
    long countByWorkshopIdAndStatus(UUID workshopId, WorkshopRegistrationStatus status);
}
