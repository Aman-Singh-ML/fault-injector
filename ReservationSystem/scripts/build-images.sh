#!/bin/bash

# Enhanced Docker Image Build Script for Hotel Reservation System
# This script builds all Docker images for the microservices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REGISTRY=${DOCKER_REGISTRY:-""}
TAG=${IMAGE_TAG:-"latest"}
PUSH=${PUSH_IMAGES:-"false"}
PARALLEL=${PARALLEL_BUILD:-"false"}
PLATFORM=${DOCKER_PLATFORM:-"linux/amd64,linux/arm64"}

# Service definitions
declare -A SERVICES=(
    ["gateway"]="gateway"
    ["auth-service"]="services/auth-service"
    ["search-service"]="services/search-service"
    ["booking-service"]="services/booking-service"
    ["payment-service"]="services/payment-service"
    ["notification-service"]="services/notification-service"
)

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to setup Docker buildx
setup_buildx() {
    print_status $YELLOW "🔧 Setting up Docker buildx for multi-platform builds..."

    # Create buildx builder if it doesn't exist
    if ! docker buildx ls | grep -q "multiarch"; then
        docker buildx create --name multiarch --driver docker-container --use
        docker buildx inspect --bootstrap
    else
        docker buildx use multiarch
    fi

    print_status $GREEN "✅ Docker buildx ready for platforms: $PLATFORM"
}

# Function to print header
print_header() {
    echo ""
    print_status $BLUE "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_status $BLUE "$1"
    print_status $BLUE "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Function to build a single service
build_service() {
    local service_name=$1
    local service_path=$2
    local image_name="${service_name}:${TAG}"
    
    if [ ! -z "$REGISTRY" ]; then
        image_name="${REGISTRY}/${image_name}"
    fi
    
    print_status $YELLOW "🔨 Building ${service_name}..."
    
    # Check if Dockerfile exists
    if [ ! -f "${service_path}/Dockerfile" ]; then
        print_status $RED "❌ Dockerfile not found in ${service_path}"
        return 1
    fi
    
    # Build the image with multi-platform support
    local build_args="--platform $PLATFORM -t $image_name"

    # Use --load only for single platform builds
    if [[ "$PLATFORM" != *","* ]]; then
        build_args="$build_args --load"
    fi

    if docker buildx build $build_args "$service_path"; then
        print_status $GREEN "✅ ${service_name} built successfully"
        
        # Get image size
        local size=$(docker images --format "table {{.Size}}" "$image_name" | tail -n 1)
        print_status $CYAN "   📦 Image size: $size"
        
        # Push if requested
        if [ "$PUSH" = "true" ] && [ ! -z "$REGISTRY" ]; then
            print_status $YELLOW "📤 Pushing ${image_name}..."
            if docker push "$image_name"; then
                print_status $GREEN "✅ ${service_name} pushed successfully"
            else
                print_status $RED "❌ Failed to push ${service_name}"
                return 1
            fi
        fi
        
        return 0
    else
        print_status $RED "❌ Failed to build ${service_name}"
        return 1
    fi
}

# Function to build services in parallel
build_parallel() {
    local pids=()
    local failed_services=()
    
    for service_name in "${!SERVICES[@]}"; do
        service_path="${SERVICES[$service_name]}"
        build_service "$service_name" "$service_path" &
        pids+=($!)
    done
    
    # Wait for all builds to complete
    for i in "${!pids[@]}"; do
        if ! wait "${pids[$i]}"; then
            failed_services+=("${!SERVICES[@]:$i:1}")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        print_status $RED "❌ Failed to build: ${failed_services[*]}"
        return 1
    fi
}

# Function to build services sequentially
build_sequential() {
    local failed_services=()
    
    for service_name in "${!SERVICES[@]}"; do
        service_path="${SERVICES[$service_name]}"
        if ! build_service "$service_name" "$service_path"; then
            failed_services+=("$service_name")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        print_status $RED "❌ Failed to build: ${failed_services[*]}"
        return 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status $YELLOW "🔍 Checking prerequisites..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_status $RED "❌ Docker is not running. Please start Docker first."
        exit 1
    fi
    
    print_status $GREEN "✅ Docker is running"
    
    # Check if all service directories exist
    for service_name in "${!SERVICES[@]}"; do
        service_path="${SERVICES[$service_name]}"
        if [ ! -d "$service_path" ]; then
            print_status $RED "❌ Service directory not found: $service_path"
            exit 1
        fi
    done
    
    print_status $GREEN "✅ All service directories found"
}

# Function to display configuration
display_config() {
    print_status $CYAN "📋 Build Configuration:"
    print_status $CYAN "   Registry: ${REGISTRY:-"(local)"}"
    print_status $CYAN "   Tag: $TAG"
    print_status $CYAN "   Push Images: $PUSH"
    print_status $CYAN "   Parallel Build: $PARALLEL"
    print_status $CYAN "   Services: ${!SERVICES[*]}"
    echo ""
}

# Function to cleanup old images
cleanup_old_images() {
    if [ "$CLEANUP" = "true" ]; then
        print_status $YELLOW "🧹 Cleaning up old images..."
        docker image prune -f
        print_status $GREEN "✅ Cleanup completed"
    fi
}

# Function to display summary
display_summary() {
    print_status $GREEN "📊 Build Summary:"
    
    for service_name in "${!SERVICES[@]}"; do
        local image_name="${service_name}:${TAG}"
        if [ ! -z "$REGISTRY" ]; then
            image_name="${REGISTRY}/${image_name}"
        fi
        
        if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "$image_name"; then
            local size=$(docker images --format "table {{.Size}}" "$image_name" | tail -n 1)
            print_status $GREEN "   ✅ $service_name ($size)"
        else
            print_status $RED "   ❌ $service_name (not found)"
        fi
    done
}

# Main execution
main() {
    print_header "🚀 BUILDING HOTEL RESERVATION SYSTEM DOCKER IMAGES"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --registry)
                REGISTRY="$2"
                shift 2
                ;;
            --tag)
                TAG="$2"
                shift 2
                ;;
            --push)
                PUSH="true"
                shift
                ;;
            --parallel)
                PARALLEL="true"
                shift
                ;;
            --platform)
                PLATFORM="$2"
                shift 2
                ;;
            --cleanup)
                CLEANUP="true"
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --registry REGISTRY  Docker registry to use"
                echo "  --tag TAG           Image tag (default: latest)"
                echo "  --platform PLATFORM Target platform(s) (default: linux/amd64,linux/arm64)"
                echo "  --push              Push images to registry"
                echo "  --parallel          Build images in parallel"
                echo "  --cleanup           Cleanup old images after build"
                echo "  --help              Show this help message"
                exit 0
                ;;
            *)
                print_status $RED "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    check_prerequisites
    setup_buildx
    display_config

    # Start build process
    local start_time=$(date +%s)
    
    if [ "$PARALLEL" = "true" ]; then
        print_status $YELLOW "🔄 Building services in parallel..."
        build_parallel
    else
        print_status $YELLOW "🔄 Building services sequentially..."
        build_sequential
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    cleanup_old_images
    display_summary
    
    print_status $GREEN "🎉 Build completed in ${duration} seconds!"
    
    if [ "$PUSH" = "true" ] && [ ! -z "$REGISTRY" ]; then
        print_status $CYAN "📤 All images pushed to registry: $REGISTRY"
    fi
}

# Run main function
main "$@"
