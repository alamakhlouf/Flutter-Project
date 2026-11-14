package com.servicehub.controller;

import com.servicehub.dto.ApiDtos.*;
import com.servicehub.dto.DtoMapper;
import com.servicehub.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class AuthController {
    private final AuthService auth;
    public AuthController(AuthService auth) { this.auth=auth; }
    @PostMapping("/auth/register") public AuthResponse register(@Valid @RequestBody RegisterRequest request) { return auth.register(request); }
    @PostMapping("/auth/login") public AuthResponse login(@Valid @RequestBody LoginRequest request) { return auth.login(request); }
    @PostMapping("/auth/google") public AuthResponse googleAuth(@Valid @RequestBody GoogleAuthRequest request) { return auth.googleAuth(request); }
    @GetMapping("/auth/me") public UserDto me() { return DtoMapper.user(auth.me()); }
    @GetMapping("/users/me") public UserDto profile() { return DtoMapper.user(auth.me()); }
    @PutMapping("/users/me") public UserDto update(@Valid @RequestBody ProfileUpdate request) { return DtoMapper.user(auth.update(request)); }
}
