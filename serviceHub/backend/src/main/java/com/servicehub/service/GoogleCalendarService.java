package com.servicehub.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleCredential;
import com.google.api.client.googleapis.auth.oauth2.GoogleTokenResponse;
import com.google.api.client.googleapis.json.GoogleJsonResponseException;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.calendar.Calendar;
import com.google.api.services.calendar.CalendarScopes;
import com.google.api.services.calendar.model.*;
import com.servicehub.entity.ProviderGoogleToken;
import com.servicehub.entity.User;
import com.servicehub.entity.Workshop;
import com.servicehub.exception.ApiException;
import com.servicehub.repository.ProviderGoogleTokenRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
public class GoogleCalendarService {
    private static final Logger log = LoggerFactory.getLogger(GoogleCalendarService.class);
    private static final JsonFactory JSON_FACTORY = GsonFactory.getDefaultInstance();
    private static final List<String> SCOPES = Arrays.asList(
            CalendarScopes.CALENDAR,
            CalendarScopes.CALENDAR_EVENTS,
            "email",
            "profile"
    );

    private final ProviderGoogleTokenRepository tokenRepository;
    private final String clientId;
    private final String clientSecret;
    private final String redirectUri;

    public GoogleCalendarService(ProviderGoogleTokenRepository tokenRepository,
                                 @Value("${app.google.client-id:}") String clientId,
                                 @Value("${app.google.client-secret:}") String clientSecret,
                                 @Value("${app.google.redirect-uri:http://localhost:8080/api/integrations/google/callback}") String redirectUri) {
        this.tokenRepository = tokenRepository;
        this.clientId = clientId != null ? clientId.trim() : "";
        this.clientSecret = clientSecret != null ? clientSecret.trim() : "";
        this.redirectUri = redirectUri != null ? redirectUri.trim() : "http://localhost:8080/api/integrations/google/callback";
    }

    private void checkConfiguration() {
        if (clientId.isBlank() || clientSecret.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Google Client ID or Secret is not configured in backend application.yml");
        }
    }

    public Map<String, Object> getStatus(User provider) {
        Optional<ProviderGoogleToken> tokenOpt = tokenRepository.findByProviderId(provider.getId());
        if (tokenOpt.isEmpty()) {
            return Map.of("connected", false);
        }
        ProviderGoogleToken token = tokenOpt.get();
        boolean connected = token.getAccessToken() != null && !token.getAccessToken().isBlank();
        Map<String, Object> result = new HashMap<>();
        result.put("connected", connected);
        if (token.getGoogleEmail() != null) {
            result.put("googleEmail", token.getGoogleEmail());
        }
        return result;
    }

    public String getAuthorizationUrl(String state) {
        checkConfiguration();
        try {
            HttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
            GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
                    httpTransport, JSON_FACTORY, clientId, clientSecret, SCOPES)
                    .setAccessType("offline")
                    .setApprovalPrompt("force")
                    .build();
            return flow.newAuthorizationUrl()
                    .setRedirectUri(redirectUri)
                    .setState(state)
                    .build();
        } catch (Exception e) {
            log.error("Failed to generate Google auth URL", e);
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to initialize Google OAuth flow");
        }
    }

    @Transactional
    public void handleCallback(String code, User provider) {
        checkConfiguration();
        try {
            HttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
            GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
                    httpTransport, JSON_FACTORY, clientId, clientSecret, SCOPES)
                    .setAccessType("offline")
                    .build();

            GoogleTokenResponse tokenResponse = flow.newTokenRequest(code)
                    .setRedirectUri(redirectUri)
                    .execute();

            ProviderGoogleToken token = tokenRepository.findByProviderId(provider.getId())
                    .orElseGet(() -> {
                        ProviderGoogleToken t = new ProviderGoogleToken();
                        t.setProvider(provider);
                        return t;
                    });

            token.setAccessToken(tokenResponse.getAccessToken());
            if (tokenResponse.getRefreshToken() != null) {
                token.setRefreshToken(tokenResponse.getRefreshToken());
            }
            if (tokenResponse.getExpiresInSeconds() != null) {
                token.setTokenExpiresAt(Instant.now().plusSeconds(tokenResponse.getExpiresInSeconds()));
            }

            tokenRepository.save(token);
        } catch (Exception e) {
            log.error("Failed to exchange authorization code for Google token", e);
            throw new ApiException(HttpStatus.BAD_REQUEST, "Google authentication callback failed: " + e.getMessage());
        }
    }

    @Transactional
    public void saveTokenFromApp(User provider, String accessToken, String refreshToken, String email) {
        if (accessToken == null || accessToken.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Access token is required");
        }
        ProviderGoogleToken token = tokenRepository.findByProviderId(provider.getId())
                .orElseGet(() -> {
                    ProviderGoogleToken t = new ProviderGoogleToken();
                    t.setProvider(provider);
                    return t;
                });

        token.setAccessToken(accessToken.trim());
        if (refreshToken != null && !refreshToken.isBlank()) {
            token.setRefreshToken(refreshToken.trim());
        }
        if (email != null && !email.isBlank()) {
            token.setGoogleEmail(email.trim());
        }
        token.setTokenExpiresAt(Instant.now().plusSeconds(3600));
        tokenRepository.save(token);
    }

    @Transactional
    public String createMeetEvent(Workshop workshop, User provider) {
        checkConfiguration();
        ProviderGoogleToken token = tokenRepository.findByProviderId(provider.getId())
                .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, "Provider Google account is not connected. Please connect Google Calendar first."));

        Calendar calendar = buildCalendarClient(token);

        try {
            Event event = new Event()
                    .setSummary(workshop.getTitle())
                    .setDescription(workshop.getDescription() != null ? workshop.getDescription() : "ServiceHub Online Workshop");

            EventDateTime start = new EventDateTime().setDateTime(new com.google.api.client.util.DateTime(workshop.getStartDateTime().toEpochMilli()));
            EventDateTime end = new EventDateTime().setDateTime(new com.google.api.client.util.DateTime(workshop.getEndDateTime().toEpochMilli()));
            event.setStart(start);
            event.setEnd(end);

            ConferenceData conferenceData = new ConferenceData();
            CreateConferenceRequest createRequest = new CreateConferenceRequest();
            createRequest.setRequestId(UUID.randomUUID().toString());
            ConferenceSolutionKey solutionKey = new ConferenceSolutionKey();
            solutionKey.setType("hangoutsMeet");
            createRequest.setConferenceSolutionKey(solutionKey);
            conferenceData.setCreateRequest(createRequest);
            event.setConferenceData(conferenceData);

            Event createdEvent = calendar.events().insert("primary", event)
                    .setConferenceDataVersion(1)
                    .execute();

            String meetUrl = null;
            if (createdEvent.getHangoutLink() != null) {
                meetUrl = createdEvent.getHangoutLink();
            } else if (createdEvent.getConferenceData() != null && createdEvent.getConferenceData().getEntryPoints() != null) {
                for (EntryPoint entryPoint : createdEvent.getConferenceData().getEntryPoints()) {
                    if ("video".equals(entryPoint.getEntryPointType())) {
                        meetUrl = entryPoint.getUri();
                        break;
                    }
                }
            }

            if (meetUrl == null) {
                throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Google Calendar API did not return a Google Meet conference link");
            }

            workshop.setMeetingUrl(meetUrl);
            workshop.setGoogleCalendarEventId(createdEvent.getId());
            return meetUrl;

        } catch (ApiException e) {
            throw e;
        } catch (GoogleJsonResponseException e) {
            if (e.getStatusCode() == HttpStatus.UNAUTHORIZED.value()) {
                log.warn("Google rejected the Calendar credentials for workshop {}", workshop.getId());
                throw new ApiException(HttpStatus.UNAUTHORIZED,
                        "Google Calendar authorization is invalid or expired. Please reconnect your Google account.");
            }
            log.error("Google Calendar API rejected workshop event creation", e);
            throw new ApiException(HttpStatus.BAD_GATEWAY, "Google Calendar API error: " + e.getMessage());
        } catch (Exception e) {
            log.error("Failed to create Google Meet event for workshop", e);
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Google Calendar API error: " + e.getMessage());
        }
    }

    @Transactional
    public void deleteEvent(Workshop workshop, User provider) {
        if (workshop.getGoogleCalendarEventId() == null) return;
        Optional<ProviderGoogleToken> tokenOpt = tokenRepository.findByProviderId(provider.getId());
        if (tokenOpt.isEmpty()) return;

        try {
            Calendar calendar = buildCalendarClient(tokenOpt.get());
            calendar.events().delete("primary", workshop.getGoogleCalendarEventId()).execute();
        } catch (Exception e) {
            log.warn("Failed to delete Google Calendar event: {}", e.getMessage());
        }
    }

    private Calendar buildCalendarClient(ProviderGoogleToken token) {
        try {
            HttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
            GoogleCredential credential = new GoogleCredential.Builder()
                    .setTransport(httpTransport)
                    .setJsonFactory(JSON_FACTORY)
                    .setClientSecrets(clientId, clientSecret)
                    .build()
                    .setAccessToken(token.getAccessToken())
                    .setRefreshToken(token.getRefreshToken());

            boolean tokenExpired = token.getTokenExpiresAt() == null
                    || Instant.now().isAfter(token.getTokenExpiresAt().minusSeconds(60));
            if (tokenExpired && token.getRefreshToken() == null) {
                throw new ApiException(HttpStatus.UNAUTHORIZED,
                        "Google Calendar authorization expired. Please reconnect your Google account.");
            }
            if (tokenExpired) {
                boolean refreshed = credential.refreshToken();
                if (!refreshed) {
                    throw new ApiException(HttpStatus.UNAUTHORIZED,
                            "Google Calendar authorization expired. Please reconnect your Google account.");
                }
                token.setAccessToken(credential.getAccessToken());
                if (credential.getExpiresInSeconds() != null) {
                    token.setTokenExpiresAt(Instant.now().plusSeconds(credential.getExpiresInSeconds()));
                }
                tokenRepository.save(token);
            }

            return new Calendar.Builder(httpTransport, JSON_FACTORY, credential)
                    .setApplicationName("ServiceHub")
                    .build();
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("Failed to build Google Calendar client", e);
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Google Calendar credentials expired or invalid. Please reconnect your account.");
        }
    }
}
