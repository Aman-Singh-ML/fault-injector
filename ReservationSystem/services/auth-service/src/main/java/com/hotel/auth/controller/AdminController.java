package com.hotel.auth.controller;

import com.hotel.auth.model.User;
import com.hotel.auth.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {
    
    private final AdminService adminService;
    
    /**
     * GET /admin/users - Get all users with details
     */
    @GetMapping("/users")
    public ResponseEntity<?> getAllUsers(
            @RequestParam(required = false) String role,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size
    ) {
        try {
            List<User> users;
            if (role != null && !role.isEmpty()) {
                users = adminService.getUsersByRole(User.UserRole.valueOf(role.toUpperCase()));
            } else {
                users = adminService.getAllUsers(page, size);
            }
            
            // Remove password from response
            users.forEach(user -> user.setPassword(null));
            
            Map<String, Object> response = new HashMap<>();
            response.put("users", users);
            response.put("total", users.size());
            response.put("page", page);
            response.put("size", size);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Failed to fetch users: " + e.getMessage()));
        }
    }
    
    /**
     * GET /admin/users/count - Get total user count
     */
    @GetMapping("/users/count")
    public ResponseEntity<?> getUserCount() {
        try {
            long totalCount = adminService.getTotalUserCount();
            long customerCount = adminService.getUserCountByRole(User.UserRole.CUSTOMER);
            long adminCount = adminService.getUserCountByRole(User.UserRole.ADMIN);
            long managerCount = adminService.getUserCountByRole(User.UserRole.HOTEL_MANAGER);
            
            Map<String, Object> response = new HashMap<>();
            response.put("total", totalCount);
            response.put("customers", customerCount);
            response.put("admins", adminCount);
            response.put("hotelManagers", managerCount);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Failed to get user count: " + e.getMessage()));
        }
    }
    
    /**
     * GET /admin/users/{id} - Get user by ID
     */
    @GetMapping("/users/{id}")
    public ResponseEntity<?> getUserById(@PathVariable Long id) {
        try {
            User user = adminService.getUserById(id);
            user.setPassword(null); // Remove password from response
            return ResponseEntity.ok(user);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "User not found: " + e.getMessage()));
        }
    }
    
    /**
     * PUT /admin/users/{id}/role - Update user role
     */
    @PutMapping("/users/{id}/role")
    public ResponseEntity<?> updateUserRole(
            @PathVariable Long id,
            @RequestBody Map<String, String> request
    ) {
        try {
            String roleStr = request.get("role");
            if (roleStr == null || roleStr.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Role is required"));
            }
            
            User.UserRole role = User.UserRole.valueOf(roleStr.toUpperCase());
            User updatedUser = adminService.updateUserRole(id, role);
            updatedUser.setPassword(null);
            
            return ResponseEntity.ok(Map.of(
                    "message", "User role updated successfully",
                    "user", updatedUser
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Invalid role: " + request.get("role")));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Failed to update user role: " + e.getMessage()));
        }
    }
    
    /**
     * PUT /admin/users/{id}/status - Enable/disable user
     */
    @PutMapping("/users/{id}/status")
    public ResponseEntity<?> updateUserStatus(
            @PathVariable Long id,
            @RequestBody Map<String, Boolean> request
    ) {
        try {
            Boolean enabled = request.get("enabled");
            if (enabled == null) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Enabled status is required"));
            }
            
            User updatedUser = adminService.updateUserStatus(id, enabled);
            updatedUser.setPassword(null);
            
            return ResponseEntity.ok(Map.of(
                    "message", "User status updated successfully",
                    "user", updatedUser
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Failed to update user status: " + e.getMessage()));
        }
    }
    
    /**
     * DELETE /admin/users/{id} - Delete user (soft delete by disabling)
     */
    @DeleteMapping("/users/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable Long id) {
        try {
            adminService.deleteUser(id);
            return ResponseEntity.ok(Map.of(
                    "message", "User deleted successfully",
                    "userId", id
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Failed to delete user: " + e.getMessage()));
        }
    }
    
    /**
     * GET /admin/stats - Get overall statistics
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getStats() {
        try {
            Map<String, Object> stats = adminService.getSystemStats();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Failed to get stats: " + e.getMessage()));
        }
    }
}

