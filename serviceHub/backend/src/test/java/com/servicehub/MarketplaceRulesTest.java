package com.servicehub;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.servicehub.entity.Role;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.Instant;
import java.math.BigDecimal;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("local")
class MarketplaceRulesTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    @Test void roleOwnershipAndInventoryValidationAreEnforced() throws Exception {
        String customer=token(Role.CUSTOMER), provider=loginSeedProvider();
        mvc.perform(post("/api/inventory").header("Authorization","Bearer "+customer).contentType(MediaType.APPLICATION_JSON)
                .content(inventoryPayload(2))).andExpect(status().isForbidden());
        String item=body(mvc.perform(post("/api/inventory").header("Authorization","Bearer "+provider).contentType(MediaType.APPLICATION_JSON)
                .content(inventoryPayload(3))).andExpect(status().isOk()).andReturn()).get("id").asText();
        mvc.perform(get("/api/inventory/"+item).header("Authorization","Bearer "+customer)).andExpect(status().isForbidden());
        mvc.perform(post("/api/inventory").header("Authorization","Bearer "+provider).contentType(MediaType.APPLICATION_JSON)
                .content(inventoryPayload(-1))).andExpect(status().isBadRequest());
    }

    @Test void supplierProductImageUrlPersistsInTheDatabase() throws Exception {
        String supplier=loginSeedSupplier();
        String imageUrl="https://example.test/products/"+"x".repeat(300)+".jpg";
        String request="{\"name\":\"Brass ball valve\",\"category\":\"Plumbing\",\"price\":12.50,"
                +"\"imageUrl\":\""+imageUrl+"\",\"quantityAvailable\":40,\"available\":true}";
        JsonNode created=body(mvc.perform(post("/api/products").header("Authorization","Bearer "+supplier)
                .contentType(MediaType.APPLICATION_JSON).content(request))
                .andExpect(status().isOk()).andReturn());
        assertEquals(imageUrl,created.get("imageUrl").asText());

        JsonNode loaded=body(mvc.perform(get("/api/products/"+created.get("id").asText()))
                .andExpect(status().isOk()).andReturn());
        assertEquals(imageUrl,loaded.get("imageUrl").asText());
    }

    @Test void bookingTransitionsReviewEligibilityAndNotificationOwnershipWork() throws Exception {
        String customer=token(Role.CUSTOMER), provider=loginSeedProvider();
        JsonNode catalog=body(mvc.perform(get("/api/services")).andExpect(status().isOk()).andReturn());
        String serviceId=catalog.get("content").get(0).get("id").asText();
        String booking=body(mvc.perform(post("/api/bookings").header("Authorization","Bearer "+customer).contentType(MediaType.APPLICATION_JSON)
                .content("{\"serviceId\":\""+serviceId+"\",\"preferredDateTime\":\""+Instant.now().plusSeconds(86400)+"\"}"))
                .andExpect(status().isOk()).andReturn()).get("id").asText();
        mvc.perform(patch("/api/bookings/"+booking+"/status").header("Authorization","Bearer "+provider).contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"ACCEPTED\"}")).andExpect(status().isOk());
        mvc.perform(patch("/api/bookings/"+booking+"/status").header("Authorization","Bearer "+provider).contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"IN_PROGRESS\"}")).andExpect(status().isOk());
        mvc.perform(patch("/api/bookings/"+booking+"/status").header("Authorization","Bearer "+provider).contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"COMPLETED\"}")).andExpect(status().isOk());
        mvc.perform(patch("/api/bookings/"+booking+"/status").header("Authorization","Bearer "+provider).contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"CANCELLED\"}")).andExpect(status().isBadRequest());
        String review="{\"bookingId\":\""+booking+"\",\"rating\":5,\"comment\":\"Great\"}";
        mvc.perform(post("/api/reviews").header("Authorization","Bearer "+customer).contentType(MediaType.APPLICATION_JSON).content(review))
                .andExpect(status().isOk());
        mvc.perform(post("/api/reviews").header("Authorization","Bearer "+customer).contentType(MediaType.APPLICATION_JSON).content(review))
                .andExpect(status().isConflict());
        JsonNode notifications=body(mvc.perform(get("/api/notifications").header("Authorization","Bearer "+provider)).andExpect(status().isOk()).andReturn());
        String notificationId=notifications.get(0).get("id").asText();
        mvc.perform(patch("/api/notifications/"+notificationId+"/read").header("Authorization","Bearer "+customer))
                .andExpect(status().isForbidden());
    }

    @Test void ordersCalculateServerSideAndWorkshopRegistrationEnforcesCapacity() throws Exception {
        String customer=token(Role.CUSTOMER), anotherCustomer=token(Role.CUSTOMER), supplier=loginSeedSupplier(), provider=token(Role.PROVIDER);
        mvc.perform(get("/api/products/my")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/services/my")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/products/my").header("Authorization","Bearer "+supplier)).andExpect(status().isOk());
        mvc.perform(get("/api/products/my").header("Authorization","Bearer "+provider)).andExpect(status().isForbidden());
        JsonNode productList=body(mvc.perform(get("/api/products")).andExpect(status().isOk()).andReturn());
        String productId=productList.get("content").get(0).get("id").asText();
        JsonNode order=body(mvc.perform(post("/api/orders").header("Authorization","Bearer "+customer).contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[{\"productId\":\""+productId+"\",\"quantity\":2}]}"))
                .andExpect(status().isOk()).andReturn());
        assertEquals(0,new BigDecimal("19.00").compareTo(order.get("totalAmount").decimalValue()));
        mvc.perform(patch("/api/orders/"+order.get("id").asText()+"/status").header("Authorization","Bearer "+supplier).contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"COMPLETED\"}")).andExpect(status().isBadRequest());

        Instant start=Instant.now().plusSeconds(172800), end=Instant.now().plusSeconds(180000), deadline=Instant.now().plusSeconds(86400);
        String workshopJson="{\"title\":\"Capacity test\",\"category\":\"Test\",\"location\":\"Room\",\"capacity\":1,"
                +"\"startDateTime\":\""+start+"\",\"endDateTime\":\""+end+"\",\"registrationDeadline\":\""+deadline+"\"}";
        String workshop=body(mvc.perform(post("/api/workshops").header("Authorization","Bearer "+provider).contentType(MediaType.APPLICATION_JSON)
                .content(workshopJson)).andExpect(status().isOk()).andReturn()).get("id").asText();
        mvc.perform(patch("/api/workshops/"+workshop+"/publish").header("Authorization","Bearer "+provider)).andExpect(status().isOk());
        mvc.perform(post("/api/workshops/"+workshop+"/registrations").header("Authorization","Bearer "+customer)).andExpect(status().isOk());
        mvc.perform(post("/api/workshops/"+workshop+"/registrations").header("Authorization","Bearer "+customer)).andExpect(status().isConflict());
        mvc.perform(post("/api/workshops/"+workshop+"/registrations").header("Authorization","Bearer "+anotherCustomer)).andExpect(status().isConflict());
    }

    @Test void everyAccountRoleCanOrderSupplierProductsAndSeeTheirOrders() throws Exception {
        String customer=token(Role.CUSTOMER);
        String provider=token(Role.PROVIDER);
        String supplierBuyer=token(Role.SUPPLIER);
        String admin=loginSeedAdmin();

        JsonNode productList=body(mvc.perform(get("/api/products")).andExpect(status().isOk()).andReturn());
        String productId=productList.get("content").get(0).get("id").asText();
        String[] buyers={customer,provider,supplierBuyer,admin};
        for (String buyer:buyers) {
            JsonNode catalog=body(mvc.perform(get("/api/products").header("Authorization","Bearer "+buyer))
                    .andExpect(status().isOk()).andReturn());
            assertEquals(productId,catalog.get("content").get(0).get("id").asText());
            JsonNode order=body(mvc.perform(post("/api/orders").header("Authorization","Bearer "+buyer)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"items\":[{\"productId\":\""+productId+"\",\"quantity\":1}]}"))
                    .andExpect(status().isOk()).andReturn());
            JsonNode myOrders=body(mvc.perform(get("/api/orders/my").header("Authorization","Bearer "+buyer))
                    .andExpect(status().isOk()).andReturn());
            assertTrue(myOrders.isArray());
            assertTrue(myOrders.toString().contains(order.get("id").asText()));
        }
        mvc.perform(post("/api/orders").contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[{\"productId\":\""+productId+"\",\"quantity\":1}]}"))
                .andExpect(status().isUnauthorized());
    }

    @Test void reportModerationIsAdminOnly() throws Exception {
        String customer=token(Role.CUSTOMER), admin=loginSeedAdmin();
        String report="{\"targetType\":\"SERVICE\",\"targetId\":\""+UUID.randomUUID()+"\",\"reason\":\"Inaccurate listing\"}";
        mvc.perform(post("/api/reports").header("Authorization","Bearer "+customer).contentType(MediaType.APPLICATION_JSON).content(report))
                .andExpect(status().isOk());
        mvc.perform(get("/api/admin/reports").header("Authorization","Bearer "+customer)).andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/reports").header("Authorization","Bearer "+admin)).andExpect(status().isOk());
    }

    private String inventoryPayload(int quantity) {
        return "{\"name\":\"Test item\",\"quantity\":"+quantity+",\"unit\":\"pieces\",\"lowStockThreshold\":2}";
    }
    private String token(Role role) throws Exception {
        String email="test-"+role.name().toLowerCase()+"-"+UUID.randomUUID()+"@example.test";
        String json="{\"fullName\":\"Test User\",\"email\":\""+email+"\",\"password\":\"password123\",\"role\":\""+role+"\"}";
        return body(mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isOk()).andReturn()).get("token").asText();
    }
    private String loginSeedAdmin() throws Exception {
        return body(mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"admin@servicehub.local\",\"password\":\"ServiceHub123!\"}"))
                .andExpect(status().isOk()).andReturn()).get("token").asText();
    }
    private String loginSeedProvider() throws Exception {
        return body(mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"provider@servicehub.local\",\"password\":\"ServiceHub123!\"}"))
                .andExpect(status().isOk()).andReturn()).get("token").asText();
    }
    private String loginSeedSupplier() throws Exception {
        return body(mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"supplier@servicehub.local\",\"password\":\"ServiceHub123!\"}"))
                .andExpect(status().isOk()).andReturn()).get("token").asText();
    }
    private JsonNode body(MvcResult result) throws Exception { return mapper.readTree(result.getResponse().getContentAsString()); }
}
