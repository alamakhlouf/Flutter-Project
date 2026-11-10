package com.servicehub;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("local")
class AuthSecurityTest {
    @Autowired MockMvc mvc;

    @Test void registrationCannotCreateAdministrator() throws Exception {
        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"fullName":"Not Admin","email":"no-admin@example.test","password":"password123","role":"ADMIN"}
                        """))
                .andExpect(status().isForbidden());
    }

    @Test void registrationCreatesCustomerAndReturnsJwt() throws Exception {
        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"fullName":"Test Customer","email":"test-customer@example.test","password":"password123","role":"CUSTOMER"}
                        """))
                .andExpect(status().isOk());
    }
}
