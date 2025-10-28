package com.hotel.auth.service;

import com.hotel.auth.controller.AuthController;
import com.hotel.auth.model.User;
import com.hotel.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final Logger logger = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    
    public User register(Object registerRequest) throws Exception {
        // Use reflection to get fields from the request object
        String email = (String) registerRequest.getClass().getMethod("getEmail").invoke(registerRequest);
        String password = (String) registerRequest.getClass().getMethod("getPassword").invoke(registerRequest);
        String firstName = (String) registerRequest.getClass().getMethod("getFirstName").invoke(registerRequest);
        String lastName = (String) registerRequest.getClass().getMethod("getLastName").invoke(registerRequest);
        String phoneNumber = (String) registerRequest.getClass().getMethod("getPhoneNumber").invoke(registerRequest);
        
        if (userRepository.existsByEmail(email)) {
            throw new Exception("Email already registered");
        }
        
        User user = new User();
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(password));
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setPhoneNumber(phoneNumber);
        user.setRole(User.UserRole.CUSTOMER);
        user.setEnabled(true);
        
        return userRepository.save(user);
    }
    
    public User login(String email, String password) throws Exception {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new Exception("User not found"));
        
        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new Exception("Invalid password");
        }
        
        if (!user.isEnabled()) {
            throw new Exception("Account is disabled");
        }
        
        return user;
    }
    
    @Cacheable(value = "users", key = "#email")
    public User getUserByEmail(String email) throws Exception {
        logger.info("🔍 Fetching user from database for email: {}", email);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new Exception("User not found"));
        logger.info("✅ User fetched and will be cached: {}", email);
        return user;
    }

    public User updateProfile(String email, Object updateRequest) throws Exception {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new Exception("User not found"));

        // Use reflection to get fields from the request object
        try {
            String firstName = (String) updateRequest.getClass().getMethod("getFirstName").invoke(updateRequest);
            String lastName = (String) updateRequest.getClass().getMethod("getLastName").invoke(updateRequest);
            String phoneNumber = (String) updateRequest.getClass().getMethod("getPhoneNumber").invoke(updateRequest);

            if (firstName != null && !firstName.isEmpty()) {
                user.setFirstName(firstName);
            }
            if (lastName != null && !lastName.isEmpty()) {
                user.setLastName(lastName);
            }
            if (phoneNumber != null && !phoneNumber.isEmpty()) {
                user.setPhoneNumber(phoneNumber);
            }
        } catch (Exception e) {
            throw new Exception("Failed to update profile: " + e.getMessage());
        }

        return userRepository.save(user);
    }
}

