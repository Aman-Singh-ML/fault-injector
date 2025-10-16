#!/bin/bash

# Helm Upgrade Script for Hotel Reservation System
# This script handles upgrading an existing Helm deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE=${NAMESPACE:-"hotel-reservation"}
RELEASE_NAME=${RELEASE_NAME:-"hotel-reservation"}
CHART_PATH=${CHART_PATH:-"helm/hotel-reservation-system"}
VALUES_FILE=${VALUES_FILE:-""}
TIMEOUT=${TIMEOUT:-"15m"}
BUILD_IMAGES=${BUILD_IMAGES:-"true"}
WAIT_FOR_READY=${WAIT_FOR_READY:-"true"}
DRY_RUN=${DRY_RUN:-"false"}
FORCE=${FORCE:-"false"}

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print header
print_header() {
    echo ""
    print_status $BLUE "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_status $BLUE "$1"
    print_status $BLUE "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Function to check if release exists
check_release_exists() {
    print_status $YELLOW "🔍 Checking if release exists..."
    
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        print_status $GREEN "✅ Release '$RELEASE_NAME' found in namespace '$NAMESPACE'"
        return 0
    else
        print_status $RED "❌ Release '$RELEASE_NAME' not found in namespace '$NAMESPACE'"
        print_status $YELLOW "Available releases:"
        helm list -n "$NAMESPACE"
        exit 1
    fi
}

# Function to show current release info
show_current_release() {
    print_status $CYAN "📊 Current Release Information:"
    helm status "$RELEASE_NAME" -n "$NAMESPACE"
    echo ""
    
    print_status $CYAN "📈 Release History:"
    helm history "$RELEASE_NAME" -n "$NAMESPACE"
    echo ""
}

# Function to show what will change
show_diff() {
    print_status $YELLOW "🔍 Analyzing changes..."
    
    # Generate current and new manifests
    local current_manifest="/tmp/current-manifest.yaml"
    local new_manifest="/tmp/new-manifest.yaml"
    
    # Get current manifest
    helm get manifest "$RELEASE_NAME" -n "$NAMESPACE" > "$current_manifest"
    
    # Generate new manifest
    local helm_cmd="helm template $RELEASE_NAME $CHART_PATH --namespace $NAMESPACE"
    if [ ! -z "$VALUES_FILE" ]; then
        helm_cmd="$helm_cmd --values $VALUES_FILE"
    fi
    
    $helm_cmd > "$new_manifest"
    
    # Show diff if available
    if command -v diff &> /dev/null; then
        print_status $CYAN "📋 Changes to be applied:"
        if diff -u "$current_manifest" "$new_manifest" || true; then
            print_status $YELLOW "No differences found in manifests"
        fi
    else
        print_status $YELLOW "⚠️  diff command not available, skipping change preview"
    fi
    
    # Cleanup
    rm -f "$current_manifest" "$new_manifest"
}

# Function to build images if needed
build_images() {
    if [ "$BUILD_IMAGES" = "true" ]; then
        print_status $YELLOW "🔨 Building updated Docker images..."
        
        if [ -f "scripts/build-images.sh" ]; then
            chmod +x scripts/build-images.sh
            ./scripts/build-images.sh --tag latest
        else
            print_status $RED "❌ Build script not found: scripts/build-images.sh"
            exit 1
        fi
        
        print_status $GREEN "✅ Docker images built successfully"
    else
        print_status $YELLOW "⏭️  Skipping image build (BUILD_IMAGES=false)"
    fi
}

# Function to perform the upgrade
perform_upgrade() {
    print_status $YELLOW "🚀 Performing Helm upgrade..."
    
    local helm_cmd="helm upgrade $RELEASE_NAME $CHART_PATH"
    helm_cmd="$helm_cmd --namespace $NAMESPACE"
    helm_cmd="$helm_cmd --timeout $TIMEOUT"
    
    if [ ! -z "$VALUES_FILE" ]; then
        helm_cmd="$helm_cmd --values $VALUES_FILE"
    fi
    
    if [ "$WAIT_FOR_READY" = "true" ]; then
        helm_cmd="$helm_cmd --wait"
    fi
    
    if [ "$DRY_RUN" = "true" ]; then
        helm_cmd="$helm_cmd --dry-run"
        print_status $YELLOW "🧪 Running in dry-run mode..."
    fi
    
    if [ "$FORCE" = "true" ]; then
        helm_cmd="$helm_cmd --force"
        print_status $YELLOW "⚠️  Force upgrade enabled"
    fi
    
    print_status $CYAN "Executing: $helm_cmd"
    
    if $helm_cmd; then
        if [ "$DRY_RUN" = "true" ]; then
            print_status $GREEN "✅ Dry run upgrade completed successfully"
        else
            print_status $GREEN "✅ Helm upgrade completed successfully"
        fi
    else
        print_status $RED "❌ Helm upgrade failed"
        
        # Show rollback option
        if [ "$DRY_RUN" = "false" ]; then
            print_status $YELLOW "💡 You can rollback with: helm rollback $RELEASE_NAME -n $NAMESPACE"
        fi
        exit 1
    fi
}

# Function to wait for rollout to complete
wait_for_rollout() {
    if [ "$WAIT_FOR_READY" = "true" ] && [ "$DRY_RUN" = "false" ]; then
        print_status $YELLOW "⏳ Waiting for rollout to complete..."
        
        # Get all deployments and wait for them
        local deployments=$(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
        
        for deployment in $deployments; do
            print_status $YELLOW "Waiting for deployment: $deployment"
            if kubectl rollout status deployment/"$deployment" -n "$NAMESPACE" --timeout=600s; then
                print_status $GREEN "✅ Deployment $deployment rolled out successfully"
            else
                print_status $RED "❌ Deployment $deployment failed to roll out"
                exit 1
            fi
        done
        
        print_status $GREEN "✅ All deployments rolled out successfully"
    fi
}

# Function to verify upgrade
verify_upgrade() {
    if [ "$DRY_RUN" = "false" ]; then
        print_status $YELLOW "🔍 Verifying upgrade..."
        
        # Check pod status
        local failed_pods=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Failed --no-headers | wc -l)
        local pending_pods=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Pending --no-headers | wc -l)
        
        if [ "$failed_pods" -gt 0 ]; then
            print_status $RED "❌ Found $failed_pods failed pods"
            kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Failed
            exit 1
        fi
        
        if [ "$pending_pods" -gt 0 ]; then
            print_status $YELLOW "⚠️  Found $pending_pods pending pods"
            kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Pending
        fi
        
        # Check if all pods are ready
        local total_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers | wc -l)
        local ready_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers | grep -c "Running\|Completed" || echo "0")
        
        print_status $CYAN "📊 Pod Status: $ready_pods/$total_pods ready"
        
        if [ "$ready_pods" -eq "$total_pods" ]; then
            print_status $GREEN "✅ All pods are ready"
        else
            print_status $YELLOW "⚠️  Not all pods are ready yet"
        fi
        
        # Show updated release info
        print_status $CYAN "📊 Updated Release Information:"
        helm status "$RELEASE_NAME" -n "$NAMESPACE"
    fi
}

# Function to parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            --release-name)
                RELEASE_NAME="$2"
                shift 2
                ;;
            --chart-path)
                CHART_PATH="$2"
                shift 2
                ;;
            --values-file)
                VALUES_FILE="$2"
                shift 2
                ;;
            --timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            --no-build)
                BUILD_IMAGES="false"
                shift
                ;;
            --no-wait)
                WAIT_FOR_READY="false"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --force)
                FORCE="true"
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --namespace NAMESPACE        Kubernetes namespace (default: hotel-reservation)"
                echo "  --release-name NAME          Helm release name (default: hotel-reservation)"
                echo "  --chart-path PATH            Path to Helm chart (default: helm/hotel-reservation-system)"
                echo "  --values-file FILE           Values file to use"
                echo "  --timeout TIMEOUT            Upgrade timeout (default: 15m)"
                echo "  --no-build                   Skip building Docker images"
                echo "  --no-wait                    Don't wait for rollout to complete"
                echo "  --dry-run                    Perform a dry run"
                echo "  --force                      Force upgrade (recreate resources)"
                echo "  --help                       Show this help message"
                exit 0
                ;;
            *)
                print_status $RED "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    print_header "🔄 HOTEL RESERVATION SYSTEM - HELM UPGRADE"
    
    parse_args "$@"
    check_release_exists
    show_current_release
    show_diff
    
    # Confirm upgrade unless dry-run
    if [ "$DRY_RUN" = "false" ]; then
        read -p "Do you want to proceed with the upgrade? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status $YELLOW "Upgrade cancelled by user"
            exit 0
        fi
    fi
    
    local start_time=$(date +%s)
    
    build_images
    perform_upgrade
    wait_for_rollout
    verify_upgrade
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ "$DRY_RUN" = "true" ]; then
        print_status $GREEN "🎉 Dry run upgrade completed successfully in ${duration} seconds!"
    else
        print_status $GREEN "🎉 Upgrade completed successfully in ${duration} seconds!"
        print_status $CYAN "📚 Useful commands:"
        print_status $CYAN "   View status: helm status $RELEASE_NAME -n $NAMESPACE"
        print_status $CYAN "   View history: helm history $RELEASE_NAME -n $NAMESPACE"
        print_status $CYAN "   Rollback: helm rollback $RELEASE_NAME -n $NAMESPACE"
    fi
}

# Run main function
main "$@"
