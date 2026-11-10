package com.servicehub.repository;

import com.servicehub.entity.Role;
import com.servicehub.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface UserRoleRepository extends JpaRepository<User, UUID> {
    List<User> findByRole(Role role);
}
