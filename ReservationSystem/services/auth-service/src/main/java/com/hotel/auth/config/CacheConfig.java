package com.hotel.auth.config;

import com.fasterxml.jackson.annotation.JsonTypeInfo;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.jsontype.BasicPolymorphicTypeValidator;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.time.Duration;

@Configuration
@EnableCaching
public class CacheConfig {

    private static final Logger logger = LoggerFactory.getLogger(CacheConfig.class);

    @Bean
    @Primary
    public RedisConnectionFactory redisConnectionFactory() {
        logger.info("🔧 Creating custom RedisConnectionFactory for port 6380...");
        System.out.println("🔧 Creating custom RedisConnectionFactory for port 6380...");

        RedisStandaloneConfiguration config = new RedisStandaloneConfiguration();
        config.setHostName("localhost");
        config.setPort(6380);

        LettuceConnectionFactory factory = new LettuceConnectionFactory(config);
        factory.afterPropertiesSet();

        logger.info("✅ RedisConnectionFactory created for localhost:6380");
        System.out.println("✅ RedisConnectionFactory created for localhost:6380");
        return factory;
    }

    @Bean("cacheManager")
    public CacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        logger.info("🔧 Initializing RedisCacheManager as PRIMARY cache manager...");
        System.out.println("🔧 Initializing RedisCacheManager as PRIMARY cache manager...");

        // Log the actual Redis connection details
        if (connectionFactory instanceof org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory) {
            org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory lettuceFactory =
                (org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory) connectionFactory;
            logger.info("📍 Redis Host: {}", lettuceFactory.getHostName());
            logger.info("📍 Redis Port: {}", lettuceFactory.getPort());
            System.out.println("📍 Redis Host: " + lettuceFactory.getHostName());
            System.out.println("📍 Redis Port: " + lettuceFactory.getPort());
        }

        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.registerModule(new JavaTimeModule());
        objectMapper.activateDefaultTyping(
                BasicPolymorphicTypeValidator.builder()
                        .allowIfBaseType(Object.class)
                        .build(),
                ObjectMapper.DefaultTyping.NON_FINAL,
                JsonTypeInfo.As.PROPERTY
        );

        Jackson2JsonRedisSerializer<Object> jackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer<>(objectMapper, Object.class);

        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(Duration.ofHours(1))
                .disableCachingNullValues()
                .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(new StringRedisSerializer()))
                .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(jackson2JsonRedisSerializer));

        RedisCacheManager cacheManager = RedisCacheManager.builder(connectionFactory)
                .cacheDefaults(config)
                .transactionAware()
                .build();

        logger.info("✅ RedisCacheManager initialized successfully as PRIMARY with connection: {}", connectionFactory);
        System.out.println("✅ RedisCacheManager initialized successfully as PRIMARY with connection: " + connectionFactory);
        return cacheManager;
    }

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory connectionFactory) {
        logger.info("🔧 Initializing RedisTemplate...");
        System.out.println("🔧 Initializing RedisTemplate...");

        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);

        StringRedisSerializer stringSerializer = new StringRedisSerializer();
        template.setKeySerializer(stringSerializer);
        template.setHashKeySerializer(stringSerializer);

        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.registerModule(new JavaTimeModule());
        Jackson2JsonRedisSerializer<Object> jackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer<>(objectMapper, Object.class);

        template.setValueSerializer(jackson2JsonRedisSerializer);
        template.setHashValueSerializer(jackson2JsonRedisSerializer);

        template.afterPropertiesSet();

        logger.info("✅ RedisTemplate initialized successfully");
        System.out.println("✅ RedisTemplate initialized successfully");
        return template;
    }
}

