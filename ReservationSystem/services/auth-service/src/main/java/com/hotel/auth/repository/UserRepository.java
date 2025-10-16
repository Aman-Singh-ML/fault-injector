package com.hotel.auth.repository;

import com.hotel.auth.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);

    // Admin endpoints
    List<User> findByRole(User.UserRole role);
    long countByRole(User.UserRole role);
    long countByEnabled(boolean enabled);
}

