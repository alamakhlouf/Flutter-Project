package com.servicehub.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import java.util.UUID;

@Entity @Getter @Setter
public class Report extends AuditedEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private User reporter;
    @NotBlank @Column(nullable = false) private String targetType;
    @Column(nullable = false) private UUID targetId;
    @NotBlank @Column(nullable = false) private String reason;
    @Column(length = 2000) private String description;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private ReportStatus status = ReportStatus.OPEN;
}
