package com.servicehub.repository;

import com.servicehub.entity.User;
import com.servicehub.entity.UserDeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserDeviceTokenRepository extends JpaRepository<UserDeviceToken, UUID> {
    List<UserDeviceToken> findByUser(User user);
    Optional<UserDeviceToken> findByToken(String token);
    void deleteByToken(String token);
    void deleteByUserAndToken(User user, String token);
}
