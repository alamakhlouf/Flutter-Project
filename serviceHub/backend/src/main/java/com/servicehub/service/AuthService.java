package com.servicehub.service;

import com.servicehub.dto.ApiDtos.*;
import com.servicehub.dto.DtoMapper;
import com.servicehub.entity.Role;
import com.servicehub.entity.User;
import com.servicehub.exception.ApiException;
import com.servicehub.repository.UserRepository;
import com.servicehub.security.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final CurrentUser currentUser;

    public AuthService(UserRepository users, PasswordEncoder encoder, JwtService jwt, CurrentUser currentUser) {
        this.users = users;
        this.encoder = encoder;
        this.jwt = jwt;
        this.currentUser = currentUser;
    }

    @Transactional
    public AuthResponse register(RegisterRequest input) {
        if (input.role() == Role.ADMIN) throw new ApiException(HttpStatus.FORBIDDEN, "ADMIN accounts cannot be self-registered");
        if (users.existsByEmailIgnoreCase(input.email())) throw ApiException.conflict("Email is already registered");
        User u = new User();
        u.setFullName(input.fullName().trim());
        u.setEmail(input.email().trim().toLowerCase());
        u.setPasswordHash(encoder.encode(input.password()));
        u.setRole(input.role());
        u.setPhone(input.phone());
        u.setProfileImageUrl(input.profileImageUrl());
        users.save(u);
        return new AuthResponse(jwt.generate(u), DtoMapper.user(u));
    }

    public AuthResponse login(LoginRequest input) {
        User u = users.findByEmailIgnoreCase(input.email()).orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Invalid email or password"));
        if (u.isBlocked()) throw new ApiException(HttpStatus.FORBIDDEN, "Account is blocked by administrator");
        if (!encoder.matches(input.password(), u.getPasswordHash())) throw new ApiException(HttpStatus.UNAUTHORIZED, "Invalid email or password");
        return new AuthResponse(jwt.generate(u), DtoMapper.user(u));
    }

    public User me() {
        User u = currentUser.get();
        if (u.isBlocked()) throw new ApiException(HttpStatus.FORBIDDEN, "Account is blocked by administrator");
        return u;
    }

    @Transactional
    public User update(ProfileUpdate input) {
        User u = currentUser.get();
        if (u.isBlocked()) throw new ApiException(HttpStatus.FORBIDDEN, "Account is blocked by administrator");
        u.setFullName(input.fullName().trim());
        u.setPhone(input.phone());
        u.setProfileImageUrl(input.profileImageUrl());
        return u;
    }
}
