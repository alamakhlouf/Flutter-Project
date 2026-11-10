package com.servicehub.service;

import com.servicehub.entity.User;
import com.servicehub.exception.ApiException;
import com.servicehub.repository.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class CurrentUser {
    private final UserRepository users;
    public CurrentUser(UserRepository users) { this.users = users; }
    public User get() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) throw ApiException.forbidden();
        return users.findByEmailIgnoreCase(auth.getName()).orElseThrow(() -> ApiException.forbidden());
    }
}
