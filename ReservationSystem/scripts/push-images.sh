#!/bin/bash

# Hotel Reservation System - Docker Image Push Script
# This script tags and pushes all service images to Docker Hub

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"docker.io"}
DOCKER_USERNAME=${DOCKER_USERNAME:-"amansingh2708"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}
PARALLEL=${PARALLEL_PUSH:-"false"}

# Service definitions (must match build-images.sh)
declare -A SERVICES=(
    ["gateway"]="gateway"
    ["auth-service"]="auth-service"
    ["search-service"]="search-service"
    ["booking-service"]="booking-service"
    ["payment-service"]="payment-service"
    ["notification-service"]="notification-service"
)

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print usage
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --username USERNAME    Docker Hub username (default: amansingh2708)"
    echo "  -t, --tag TAG             Image tag (default: latest)"
    echo "  -r, --registry REGISTRY   Docker registry (default: docker.io)"
    echo "  -p, --parallel            Push images in parallel"
    echo "  -s, --service SERVICE     Push specific service only"
    echo "  --dry-run                 Show what would be pushed without actually pushing"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  DOCKER_USERNAME           Docker Hub username"
    echo "  DOCKER_REGISTRY           Docker registry URL"
    echo "  IMAGE_TAG                 Image tag to use"
    echo "  PARALLEL_PUSH             Enable parallel pushing (true/false)"
    echo ""
    echo "Examples:"
    echo "  $0                        # Push all images with default settings"
    echo "  $0 -t v1.0.0             # Push all images with tag v1.0.0"
    echo "  $0 -s gateway            # Push only gateway service"
    echo "  $0 -p                    # Push all images in parallel"
    echo "  $0 --dry-run             # Show what would be pushed"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_status $RED "❌ Docker is not running or not accessible"
        print_status $YELLOW "Please start Docker and try again"
        exit 1
    fi
}

# Function to check if user is logged in to Docker Hub
check_docker_login() {
    if ! docker info | grep -q "Username: $DOCKER_USERNAME" 2>/dev/null; then
        print_status $YELLOW "⚠️  Not logged in to Docker Hub as $DOCKER_USERNAME"
        print_status $BLUE "Please run: docker login"
        read -p "Do you want to login now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker login
        else
            print_status $RED "❌ Docker login required to push images"
            exit 1
        fi
    fi
}

# Function to check if local image exists
check_local_image() {
    local service_name=$1
    if ! docker image inspect "$service_name:$IMAGE_TAG" >/dev/null 2>&1; then
        print_status $RED "❌ Local image $service_name:$IMAGE_TAG not found"
        print_status $YELLOW "Please run ./scripts/build-images.sh first"
        return 1
    fi
    return 0
}

# Function to tag and push a single service
push_service() {
    local service_name=$1
    local remote_image="$DOCKER_REGISTRY/$DOCKER_USERNAME/$service_name:$IMAGE_TAG"
    
    print_status $BLUE "📦 Processing $service_name..."
    
    # Check if local image exists
    if ! check_local_image "$service_name"; then
        return 1
    fi
    
    # Tag the image
    print_status $YELLOW "   🏷️  Tagging: $service_name:$IMAGE_TAG -> $remote_image"
    if ! docker tag "$service_name:$IMAGE_TAG" "$remote_image"; then
        print_status $RED "   ❌ Failed to tag $service_name"
        return 1
    fi
    
    # Push the image
    if [ "$DRY_RUN" = "true" ]; then
        print_status $YELLOW "   🔍 [DRY RUN] Would push: $remote_image"
        return 0
    fi
    
    print_status $YELLOW "   ⬆️  Pushing: $remote_image"
    if docker push "$remote_image"; then
        # Get image size
        local size=$(docker image inspect "$remote_image" --format='{{.Size}}' | numfmt --to=iec)
        print_status $GREEN "   ✅ $service_name pushed successfully"
        print_status $GREEN "   📦 Image size: $size"
        return 0
    else
        print_status $RED "   ❌ Failed to push $service_name"
        return 1
    fi
}

# Function to push services in parallel
push_parallel() {
    local pids=()
    local failed_services=()
    
    for service_name in "${!SERVICES[@]}"; do
        push_service "$service_name" &
        pids+=($!)
    done
    
    # Wait for all pushes to complete
    for i in "${!pids[@]}"; do
        if ! wait "${pids[$i]}"; then
            failed_services+=("${!SERVICES[$i]}")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        print_status $RED "❌ Failed to push: ${failed_services[*]}"
        return 1
    fi
}

# Function to push services sequentially
push_sequential() {
    local failed_services=()
    
    for service_name in "${!SERVICES[@]}"; do
        if ! push_service "$service_name"; then
            failed_services+=("$service_name")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        print_status $RED "❌ Failed to push: ${failed_services[*]}"
        return 1
    fi
}

# Parse command line arguments
SPECIFIC_SERVICE=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            DOCKER_USERNAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        -p|--parallel)
            PARALLEL="true"
            shift
            ;;
        -s|--service)
            SPECIFIC_SERVICE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            print_status $RED "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_status $BLUE "🚀 Hotel Reservation System - Docker Image Push"
    print_status $BLUE "================================================"
    echo
    
    # Display configuration
    print_status $YELLOW "📋 Configuration:"
    print_status $YELLOW "   Registry: $DOCKER_REGISTRY"
    print_status $YELLOW "   Username: $DOCKER_USERNAME"
    print_status $YELLOW "   Tag: $IMAGE_TAG"
    print_status $YELLOW "   Parallel: $PARALLEL"
    if [ "$DRY_RUN" = "true" ]; then
        print_status $YELLOW "   Mode: DRY RUN"
    fi
    echo
    
    # Pre-flight checks
    check_docker
    if [ "$DRY_RUN" != "true" ]; then
        check_docker_login
    fi
    
    # Push specific service or all services
    if [ -n "$SPECIFIC_SERVICE" ]; then
        if [[ -v SERVICES[$SPECIFIC_SERVICE] ]]; then
            print_status $BLUE "📦 Pushing specific service: $SPECIFIC_SERVICE"
            if push_service "$SPECIFIC_SERVICE"; then
                print_status $GREEN "🎉 Successfully pushed $SPECIFIC_SERVICE!"
            else
                exit 1
            fi
        else
            print_status $RED "❌ Unknown service: $SPECIFIC_SERVICE"
            print_status $YELLOW "Available services: ${!SERVICES[*]}"
            exit 1
        fi
    else
        print_status $BLUE "📦 Pushing all services..."
        echo
        
        if [ "$PARALLEL" = "true" ]; then
            print_status $YELLOW "⚡ Using parallel push"
            if push_parallel; then
                print_status $GREEN "🎉 All images pushed successfully!"
            else
                exit 1
            fi
        else
            print_status $YELLOW "📝 Using sequential push"
            if push_sequential; then
                print_status $GREEN "🎉 All images pushed successfully!"
            else
                exit 1
            fi
        fi
    fi
    
    echo
    print_status $GREEN "✅ Push completed!"
    
    if [ "$DRY_RUN" != "true" ]; then
        print_status $BLUE "📋 Your images are now available at:"
        for service_name in "${!SERVICES[@]}"; do
            if [ -z "$SPECIFIC_SERVICE" ] || [ "$SPECIFIC_SERVICE" = "$service_name" ]; then
                print_status $BLUE "   🔗 $DOCKER_REGISTRY/$DOCKER_USERNAME/$service_name:$IMAGE_TAG"
            fi
        done
    fi
}

# Run main function
main "$@"
