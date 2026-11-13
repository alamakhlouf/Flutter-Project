package com.servicehub.repository;

import com.servicehub.entity.Report;
import com.servicehub.entity.ReportStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface ReportRepository extends JpaRepository<Report, UUID> {
    List<Report> findByReporterId(UUID reporterId);
    List<Report> findByStatus(ReportStatus status);
}
