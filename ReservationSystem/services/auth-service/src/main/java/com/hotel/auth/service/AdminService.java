package com.hotel.auth.service;

import com.hotel.auth.model.User;
import com.hotel.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AdminService {
    
    private final UserRepository userRepository;
    
    /**
     * Get all users with pagination
     */
    public List<User> getAllUsers(int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        return userRepository.findAll(pageable).getContent();
    }
    
    /**
     * Get users by role
     */
    public List<User> getUsersByRole(User.UserRole role) {
        return userRepository.findByRole(role);
    }
    
    /**
     * Get total user count
     */
    public long getTotalUserCount() {
        return userRepository.count();
    }
    
    /**
     * Get user count by role
     */
    public long getUserCountByRole(User.UserRole role) {
        return userRepository.countByRole(role);
    }
    
    /**
     * Get user by ID
     */
    public User getUserById(Long id) throws Exception {
        return userRepository.findById(id)
                .orElseThrow(() -> new Exception("User not found with id: " + id));
    }
    
    /**
     * Update user role
     */
    public User updateUserRole(Long id, User.UserRole role) throws Exception {
        User user = getUserById(id);
        user.setRole(role);
        return userRepository.save(user);
    }
    
    /**
     * Update user status (enable/disable)
     */
    public User updateUserStatus(Long id, boolean enabled) throws Exception {
        User user = getUserById(id);
        user.setEnabled(enabled);
        return userRepository.save(user);
    }
    
    /**
     * Delete user (soft delete by disabling)
     */
    public void deleteUser(Long id) throws Exception {
        User user = getUserById(id);
        user.setEnabled(false);
        userRepository.save(user);
    }
    
    /**
     * Get system statistics
     */
    public Map<String, Object> getSystemStats() {
        Map<String, Object> stats = new HashMap<>();
        
        long totalUsers = getTotalUserCount();
        long customers = getUserCountByRole(User.UserRole.CUSTOMER);
        long admins = getUserCountByRole(User.UserRole.ADMIN);
        long managers = getUserCountByRole(User.UserRole.HOTEL_MANAGER);
        long enabledUsers = userRepository.countByEnabled(true);
        long disabledUsers = userRepository.countByEnabled(false);
        
        stats.put("totalUsers", totalUsers);
        stats.put("customers", customers);
        stats.put("admins", admins);
        stats.put("hotelManagers", managers);
        stats.put("enabledUsers", enabledUsers);
        stats.put("disabledUsers", disabledUsers);
        
        return stats;
    }
}

