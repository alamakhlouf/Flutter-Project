package com.servicehub.controller;

import com.servicehub.entity.User;
import com.servicehub.exception.ApiException;
import com.servicehub.repository.UserRepository;
import com.servicehub.security.JwtService;
import com.servicehub.service.CurrentUser;
import com.servicehub.service.GoogleCalendarService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/integrations/google")
public class IntegrationController {
    private final GoogleCalendarService googleCalendarService;
    private final CurrentUser currentUser;
    private final JwtService jwtService;
    private final UserRepository userRepository;

    public IntegrationController(GoogleCalendarService googleCalendarService, CurrentUser currentUser, JwtService jwtService, UserRepository userRepository) {
        this.googleCalendarService = googleCalendarService;
        this.currentUser = currentUser;
        this.jwtService = jwtService;
        this.userRepository = userRepository;
    }

    public record GoogleTokenRequest(String accessToken, String refreshToken, String email) { }

    @GetMapping("/status")
    public Map<String, Object> status() {
        User provider = currentUser.get();
        return googleCalendarService.getStatus(provider);
    }

    @PostMapping("/token")
    public Map<String, Object> connectToken(@RequestBody GoogleTokenRequest req) {
        User provider = currentUser.get();
        googleCalendarService.saveTokenFromApp(provider, req.accessToken(), req.refreshToken(), req.email());
        return googleCalendarService.getStatus(provider);
    }

    @GetMapping("/connect")
    public Map<String, String> connect(@RequestParam(required = false) String token) {
        User provider = currentUser.get();
        String state = token != null ? token : jwtService.generate(provider);
        String url = googleCalendarService.getAuthorizationUrl(state);
        return Map.of("authUrl", url);
    }

    @GetMapping("/callback")
    public ResponseEntity<String> callback(@RequestParam String code, @RequestParam(required = false) String state) {
        User provider = null;
        if (state != null && !state.isBlank()) {
            try {
                String email = jwtService.subject(state);
                provider = userRepository.findByEmailIgnoreCase(email).orElse(null);
            } catch (Exception ignored) {}
        }
        if (provider == null) {
            try {
                provider = currentUser.get();
            } catch (Exception e) {
                throw ApiException.invalid("Unauthorized callback or missing user session");
            }
        }
        googleCalendarService.handleCallback(code, provider);
        return ResponseEntity.ok()
                .contentType(org.springframework.http.MediaType.TEXT_HTML)
                .body("<html><body><h2>Google Calendar / Meet connected successfully!</h2><p>You can close this window and return to the ServiceHub app.</p></body></html>");
    }
}
