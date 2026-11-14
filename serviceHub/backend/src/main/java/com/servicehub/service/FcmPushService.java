package com.servicehub.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.Notification;
import com.servicehub.entity.User;
import com.servicehub.entity.UserDeviceToken;
import com.servicehub.repository.UserDeviceTokenRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.InputStream;
import java.util.List;
import java.util.UUID;

@Service
public class FcmPushService {

    private static final Logger log = LoggerFactory.getLogger(FcmPushService.class);
    private final UserDeviceTokenRepository deviceTokenRepository;
    private final String credentialsPath;
    private boolean firebaseInitialized = false;

    public FcmPushService(UserDeviceTokenRepository deviceTokenRepository,
                          @Value("${app.firebase.credentials-file:}") String credentialsPath) {
        this.deviceTokenRepository = deviceTokenRepository;
        this.credentialsPath = credentialsPath != null ? credentialsPath.trim() : "";
    }

    @PostConstruct
    public void init() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                InputStream serviceAccount = null;
                if (!credentialsPath.isBlank()) {
                    Resource resource = credentialsPath.startsWith("classpath:")
                            ? new ClassPathResource(credentialsPath.substring(10))
                            : new FileSystemResource(credentialsPath);
                    if (resource.exists()) {
                        serviceAccount = resource.getInputStream();
                    }
                }

                if (serviceAccount != null) {
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                            .build();
                    FirebaseApp.initializeApp(options);
                    firebaseInitialized = true;
                    log.info("Firebase Admin SDK initialized successfully.");
                } else {
                    log.warn("Firebase credentials file not provided or not found. In-app notifications will work; FCM push delivery is disabled.");
                }
            } else {
                firebaseInitialized = true;
            }
        } catch (Exception e) {
            log.warn("Could not initialize Firebase Admin SDK: {}", e.getMessage());
        }
    }

    public void sendPushNotification(User recipient, String title, String message, String type, String entityType, UUID entityId) {
        List<UserDeviceToken> tokens = deviceTokenRepository.findByUser(recipient);
        if (tokens.isEmpty()) return;

        List<String> tokenStrings = tokens.stream().map(UserDeviceToken::getToken).toList();

        if (!firebaseInitialized) {
            log.info("Simulated FCM Push to {} token(s) for user {}: {}", tokenStrings.size(), recipient.getEmail(), title);
            return;
        }

        try {
            MulticastMessage.Builder builder = MulticastMessage.builder()
                    .addAllTokens(tokenStrings)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(message)
                            .build())
                    .putData("type", type != null ? type : "GENERAL");

            if (entityType != null) builder.putData("relatedEntityType", entityType);
            if (entityId != null) builder.putData("relatedEntityId", entityId.toString());

            FirebaseMessaging.getInstance().sendEachForMulticastAsync(builder.build());
        } catch (Exception e) {
            log.error("Failed to send FCM push notification: {}", e.getMessage());
        }
    }
}
