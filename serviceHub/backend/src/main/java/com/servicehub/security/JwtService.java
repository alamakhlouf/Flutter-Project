package com.servicehub.security;

import com.servicehub.entity.User;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.crypto.SecretKey;
import java.security.SecureRandom;
import java.util.Date;

@Service
public class JwtService {
    private static final Logger log = LoggerFactory.getLogger(JwtService.class);
    private final SecretKey key;
    private final long expiration;
    public JwtService(@Value("${app.jwt.secret}") String secret, @Value("${app.jwt.expiration-ms}") long expiration) {
        if (secret == null || secret.isBlank()) {
            byte[] generatedKey = new byte[32];
            new SecureRandom().nextBytes(generatedKey);
            this.key = Keys.hmacShaKeyFor(generatedKey);
            log.warn("JWT_SECRET is not configured; using a temporary random signing key. Set JWT_SECRET to keep tokens valid across restarts.");
        } else {
            byte[] configuredKey = secret.getBytes(java.nio.charset.StandardCharsets.UTF_8);
            if (configuredKey.length < 32) {
                throw new IllegalArgumentException("JWT_SECRET must be at least 32 bytes");
            }
            this.key = Keys.hmacShaKeyFor(configuredKey);
        }
        this.expiration = expiration;
    }
    public String generate(User user) {
        long now = System.currentTimeMillis();
        return Jwts.builder().subject(user.getEmail()).claim("role", user.getRole().name())
                .issuedAt(new Date(now)).expiration(new Date(now + expiration)).signWith(key).compact();
    }
    public String subject(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload().getSubject();
    }
}
