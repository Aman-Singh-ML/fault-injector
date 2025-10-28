package com.hotel.auth.controller;

import com.hotel.auth.model.User;
import com.hotel.auth.service.AuthService;
import com.hotel.auth.service.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final AuthService authService;
    private final JwtService jwtService;
    
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        try {
            User user = authService.register(request);
            String token = jwtService.generateToken(user);
            
            Map<String, Object> response = new HashMap<>();
            response.put("token", token);
            response.put("user", getUserInfo(user));
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            User user = authService.login(request.getEmail(), request.getPassword());
            String token = jwtService.generateToken(user);
            
            Map<String, Object> response = new HashMap<>();
            response.put("token", token);
            response.put("user", getUserInfo(user));
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid credentials"));
        }
    }
    
    @PostMapping("/verify")
    public ResponseEntity<?> verifyToken(@RequestHeader("Authorization") String authHeader) {
        try {
            String token = authHeader.substring(7); // Remove "Bearer " prefix
            String email = jwtService.extractEmail(token);

            if (jwtService.isTokenValid(token, email)) {
                //todo replace here
                User user = authService.getUserByEmail(email);
                return ResponseEntity.ok(Map.of("user", getUserInfo(user)));
            }

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid token"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Token verification failed"));
        }
    }

    @GetMapping("/profile")
    public ResponseEntity<?> getProfile(@RequestHeader("Authorization") String authHeader) {
        try {
            String token = authHeader.substring(7); // Remove "Bearer " prefix
            String email = jwtService.extractEmail(token);
            System.out.println("🔍 Profile endpoint called for email: " + email);

            if (jwtService.isTokenValid(token, email)) {
                // Load from cached data (Redis)
                System.out.println("✅ Token valid, calling getUserByEmail...");
                User user = authService.getUserByEmail(email);
                System.out.println("✅ User retrieved: " + user.getEmail());
                return ResponseEntity.ok(Map.of("user", getUserInfo(user)));
            }

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid token"));
        } catch (Exception e) {
            System.out.println("❌ Error in profile endpoint: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Failed to get profile: " + e.getMessage()));
        }
    }

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(@RequestHeader("Authorization") String authHeader, @RequestBody UpdateProfileRequest request) {
        try {
            String token = authHeader.substring(7); // Remove "Bearer " prefix
            String email = jwtService.extractEmail(token);

            if (jwtService.isTokenValid(token, email)) {
                User user = authService.updateProfile(email, request);
                return ResponseEntity.ok(Map.of("user", getUserInfo(user)));
            }

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid token"));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Failed to update profile: " + e.getMessage()));
        }
    }


    private Map<String, Object> getUserInfo(User user) {
        Map<String, Object> userInfo = new HashMap<>();
        userInfo.put("id", user.getId());
        userInfo.put("email", user.getEmail());
        userInfo.put("firstName", user.getFirstName());
        userInfo.put("lastName", user.getLastName());
        userInfo.put("role", user.getRole());
        return userInfo;
    }

    public static class RegisterRequest {
        private String email;
        private String password;
        private String firstName;
        private String lastName;
        private String phoneNumber;

        // Getters and setters
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
        public String getFirstName() { return firstName; }
        public void setFirstName(String firstName) { this.firstName = firstName; }
        public String getLastName() { return lastName; }
        public void setLastName(String lastName) { this.lastName = lastName; }
        public String getPhoneNumber() { return phoneNumber; }
        public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    }

    public static class LoginRequest {
        private String email;
        private String password;

        // Getters and setters
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
    }

    public static class UpdateProfileRequest {
        private String firstName;
        private String lastName;
        private String phoneNumber;

        // Getters and setters
        public String getFirstName() { return firstName; }
        public void setFirstName(String firstName) { this.firstName = firstName; }
        public String getLastName() { return lastName; }
        public void setLastName(String lastName) { this.lastName = lastName; }
        public String getPhoneNumber() { return phoneNumber; }
        public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    }
}

