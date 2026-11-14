package com.servicehub.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.servicehub.dto.ApiDtos.*;
import com.servicehub.dto.DtoMapper;
import com.servicehub.entity.Role;
import com.servicehub.entity.User;
import com.servicehub.exception.ApiException;
import com.servicehub.repository.UserRepository;
import com.servicehub.security.GoogleTokenVerifier;
import com.servicehub.security.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

@Service
public class AuthService {
    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final CurrentUser currentUser;
    private final GoogleTokenVerifier googleVerifier;

    public AuthService(UserRepository users, PasswordEncoder encoder, JwtService jwt, CurrentUser currentUser, GoogleTokenVerifier googleVerifier) {
        this.users = users;
        this.encoder = encoder;
        this.jwt = jwt;
        this.currentUser = currentUser;
        this.googleVerifier = googleVerifier;
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

    @Transactional
    public AuthResponse googleAuth(GoogleAuthRequest input) {
        GoogleIdToken.Payload payload = googleVerifier.verify(input.idToken());
        String email = payload.getEmail();
        Boolean emailVerified = payload.getEmailVerified();
        if (email == null || (emailVerified != null && !emailVerified)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Google email is not verified");
        }

        String googleSub = payload.getSubject();
        String name = (String) payload.get("name");
        String pictureUrl = (String) payload.get("picture");

        Optional<User> existing = users.findByEmailIgnoreCase(email);
        if (existing.isPresent()) {
            User u = existing.get();
            if (u.isBlocked()) throw new ApiException(HttpStatus.FORBIDDEN, "Account is blocked by administrator");
            if (u.getGoogleSubjectId() == null) {
                u.setGoogleSubjectId(googleSub);
            }
            if (u.getProfileImageUrl() == null && pictureUrl != null) {
                u.setProfileImageUrl(pictureUrl);
            }
            users.save(u);
            return new AuthResponse(jwt.generate(u), DtoMapper.user(u));
        }

        // New User -> Role selection is required
        if (input.role() == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "ROLE_REQUIRED_FOR_NEW_USER");
        }
        if (input.role() == Role.ADMIN) {
            throw new ApiException(HttpStatus.FORBIDDEN, "ADMIN accounts cannot be self-registered");
        }

        User u = new User();
        u.setFullName(name != null && !name.isBlank() ? name.trim() : email.split("@")[0]);
        u.setEmail(email.trim().toLowerCase());
        u.setPasswordHash(encoder.encode(UUID.randomUUID().toString()));
        u.setRole(input.role());
        u.setProfileImageUrl(pictureUrl);
        u.setGoogleSubjectId(googleSub);
        users.save(u);

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
