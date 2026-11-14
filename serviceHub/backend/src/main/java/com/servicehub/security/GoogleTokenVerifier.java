package com.servicehub.security;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.servicehub.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.util.Collections;

@Component
public class GoogleTokenVerifier {

    private static final Logger log = LoggerFactory.getLogger(GoogleTokenVerifier.class);
    private final GoogleIdTokenVerifier verifier;

    public GoogleTokenVerifier(@Value("${app.google.client-id:}") String googleClientId) {
        GoogleIdTokenVerifier.Builder builder = new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(),
                GsonFactory.getDefaultInstance()
        );

        if (googleClientId != null && !googleClientId.isBlank()) {
            builder.setAudience(Collections.singletonList(googleClientId.trim()));
            log.info("GoogleTokenVerifier configured with expected audience client ID.");
        } else {
            log.warn("GoogleTokenVerifier configured WITHOUT audience restriction.");
        }

        this.verifier = builder.build();
    }

    public GoogleIdToken.Payload verify(String idTokenString) {
        if (idTokenString == null || idTokenString.isBlank()) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Google ID Token is missing");
        }
        try {
            GoogleIdToken idToken = verifier.verify(idTokenString.trim());
            if (idToken != null) {
                GoogleIdToken.Payload payload = idToken.getPayload();
                if (payload != null) {
                    return payload;
                }
            }
            log.error("GoogleIdToken verification returned null for token string.");
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Invalid or expired Google ID Token");
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("Exception during Google ID Token verification: {}", e.getMessage(), e);
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Failed to verify Google ID Token: " + e.getMessage());
        }
    }
}
