#!/bin/bash

# Helm Uninstall Script for Hotel Reservation System
# This script safely removes the Helm deployment and optionally cleans up resources

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
TIMEOUT=${TIMEOUT:-"5m"}
KEEP_NAMESPACE=${KEEP_NAMESPACE:-"false"}
KEEP_PVC=${KEEP_PVC:-"false"}
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
        print_status $YELLOW "⚠️  Release '$RELEASE_NAME' not found in namespace '$NAMESPACE'"
        print_status $YELLOW "Available releases:"
        helm list -n "$NAMESPACE"
        
        read -p "Continue with cleanup of remaining resources? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
        return 1
    fi
}

# Function to show current release info
show_current_release() {
    print_status $CYAN "📊 Current Release Information:"
    helm status "$RELEASE_NAME" -n "$NAMESPACE" 2>/dev/null || print_status $YELLOW "Release status not available"
    echo ""
    
    print_status $CYAN "📈 Release History:"
    helm history "$RELEASE_NAME" -n "$NAMESPACE" 2>/dev/null || print_status $YELLOW "Release history not available"
    echo ""
}

# Function to show what will be removed
show_resources_to_remove() {
    print_status $YELLOW "🔍 Resources to be removed:"
    
    # Show all resources in the namespace
    print_status $CYAN "Deployments:"
    kubectl get deployments -n "$NAMESPACE" 2>/dev/null || print_status $YELLOW "No deployments found"
    
    print_status $CYAN "StatefulSets:"
    kubectl get statefulsets -n "$NAMESPACE" 2>/dev/null || print_status $YELLOW "No statefulsets found"
    
    print_status $CYAN "Services:"
    kubectl get services -n "$NAMESPACE" 2>/dev/null || print_status $YELLOW "No services found"
    
    print_status $CYAN "ConfigMaps:"
    kubectl get configmaps -n "$NAMESPACE" 2>/dev/null || print_status $YELLOW "No configmaps found"
    
    print_status $CYAN "Secrets:"
    kubectl get secrets -n "$NAMESPACE" 2>/dev/null || print_status $YELLOW "No secrets found"
    
    if [ "$KEEP_PVC" = "false" ]; then
        print_status $CYAN "PersistentVolumeClaims (will be deleted):"
        kubectl get pvc -n "$NAMESPACE" 2>/dev/null || print_status $YELLOW "No PVCs found"
    else
        print_status $CYAN "PersistentVolumeClaims (will be kept):"
        kubectl get pvc -n "$NAMESPACE" 2>/dev/null || print_status $YELLOW "No PVCs found"
    fi
    
    echo ""
}

# Function to uninstall Helm release
uninstall_helm_release() {
    print_status $YELLOW "🗑️  Uninstalling Helm release..."
    
    local helm_cmd="helm uninstall $RELEASE_NAME --namespace $NAMESPACE"
    
    if [ "$TIMEOUT" != "" ]; then
        helm_cmd="$helm_cmd --timeout $TIMEOUT"
    fi
    
    if [ "$DRY_RUN" = "true" ]; then
        helm_cmd="$helm_cmd --dry-run"
        print_status $YELLOW "🧪 Running in dry-run mode..."
    fi
    
    print_status $CYAN "Executing: $helm_cmd"
    
    if $helm_cmd; then
        if [ "$DRY_RUN" = "true" ]; then
            print_status $GREEN "✅ Dry run uninstall completed successfully"
        else
            print_status $GREEN "✅ Helm release uninstalled successfully"
        fi
    else
        print_status $RED "❌ Helm uninstall failed"
        if [ "$FORCE" = "true" ]; then
            print_status $YELLOW "🔨 Force mode enabled, continuing with manual cleanup..."
        else
            exit 1
        fi
    fi
}

# Function to wait for resources to be deleted
wait_for_deletion() {
    if [ "$DRY_RUN" = "false" ]; then
        print_status $YELLOW "⏳ Waiting for resources to be deleted..."
        
        # Wait for deployments to be deleted
        local deployments=$(kubectl get deployments -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
        if [ "$deployments" -gt 0 ]; then
            print_status $YELLOW "Waiting for deployments to be deleted..."
            kubectl wait --for=delete deployment --all -n "$NAMESPACE" --timeout=300s 2>/dev/null || true
        fi
        
        # Wait for statefulsets to be deleted
        local statefulsets=$(kubectl get statefulsets -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
        if [ "$statefulsets" -gt 0 ]; then
            print_status $YELLOW "Waiting for statefulsets to be deleted..."
            kubectl wait --for=delete statefulset --all -n "$NAMESPACE" --timeout=300s 2>/dev/null || true
        fi
        
        # Wait for pods to be deleted
        local pods=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
        if [ "$pods" -gt 0 ]; then
            print_status $YELLOW "Waiting for pods to be deleted..."
            kubectl wait --for=delete pod --all -n "$NAMESPACE" --timeout=300s 2>/dev/null || true
        fi
        
        print_status $GREEN "✅ Resources deleted successfully"
    fi
}

# Function to cleanup PVCs
cleanup_pvcs() {
    if [ "$KEEP_PVC" = "false" ] && [ "$DRY_RUN" = "false" ]; then
        print_status $YELLOW "🗑️  Cleaning up PersistentVolumeClaims..."
        
        local pvcs=$(kubectl get pvc -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
        if [ "$pvcs" -gt 0 ]; then
            print_status $YELLOW "Deleting PVCs..."
            kubectl delete pvc --all -n "$NAMESPACE" 2>/dev/null || true
            print_status $GREEN "✅ PVCs deleted"
        else
            print_status $YELLOW "No PVCs found to delete"
        fi
    elif [ "$KEEP_PVC" = "true" ]; then
        print_status $YELLOW "⏭️  Keeping PVCs as requested"
    fi
}

# Function to cleanup namespace
cleanup_namespace() {
    if [ "$KEEP_NAMESPACE" = "false" ] && [ "$DRY_RUN" = "false" ]; then
        print_status $YELLOW "🗑️  Cleaning up namespace..."
        
        # Check if namespace exists and has any remaining resources
        if kubectl get namespace "$NAMESPACE" &>/dev/null; then
            local remaining_resources=$(kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n "$NAMESPACE" 2>/dev/null | wc -l || echo "0")
            
            if [ "$remaining_resources" -gt 0 ]; then
                print_status $YELLOW "Found $remaining_resources remaining resources in namespace"
                print_status $YELLOW "Remaining resources:"
                kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n "$NAMESPACE" 2>/dev/null || true
                
                read -p "Force delete namespace anyway? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    kubectl delete namespace "$NAMESPACE" --force --grace-period=0 2>/dev/null || true
                    print_status $GREEN "✅ Namespace force deleted"
                else
                    print_status $YELLOW "⏭️  Keeping namespace with remaining resources"
                fi
            else
                kubectl delete namespace "$NAMESPACE" 2>/dev/null || true
                print_status $GREEN "✅ Namespace deleted"
            fi
        else
            print_status $YELLOW "Namespace '$NAMESPACE' not found"
        fi
    elif [ "$KEEP_NAMESPACE" = "true" ]; then
        print_status $YELLOW "⏭️  Keeping namespace as requested"
    fi
}

# Function to cleanup Docker images (optional)
cleanup_docker_images() {
    if [ "$CLEANUP_IMAGES" = "true" ]; then
        print_status $YELLOW "🗑️  Cleaning up Docker images..."
        
        # List of image names to clean up
        local images=(
            "gateway:latest"
            "auth-service:latest"
            "search-service:latest"
            "booking-service:latest"
            "payment-service:latest"
            "notification-service:latest"
        )
        
        for image in "${images[@]}"; do
            if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "$image"; then
                print_status $YELLOW "Removing image: $image"
                docker rmi "$image" 2>/dev/null || true
            fi
        done
        
        print_status $GREEN "✅ Docker images cleaned up"
    fi
}

# Function to verify cleanup
verify_cleanup() {
    if [ "$DRY_RUN" = "false" ]; then
        print_status $YELLOW "🔍 Verifying cleanup..."
        
        # Check if release still exists
        if helm list -n "$NAMESPACE" 2>/dev/null | grep -q "$RELEASE_NAME"; then
            print_status $RED "❌ Release still exists"
        else
            print_status $GREEN "✅ Release removed"
        fi
        
        # Check remaining resources
        local remaining_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
        local remaining_services=$(kubectl get services -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
        local remaining_deployments=$(kubectl get deployments -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
        
        print_status $CYAN "📊 Cleanup Summary:"
        print_status $CYAN "   Remaining pods: $remaining_pods"
        print_status $CYAN "   Remaining services: $remaining_services"
        print_status $CYAN "   Remaining deployments: $remaining_deployments"
        
        if [ "$remaining_pods" -eq 0 ] && [ "$remaining_services" -eq 0 ] && [ "$remaining_deployments" -eq 0 ]; then
            print_status $GREEN "✅ Cleanup completed successfully"
        else
            print_status $YELLOW "⚠️  Some resources may still exist"
        fi
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
            --timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            --keep-namespace)
                KEEP_NAMESPACE="true"
                shift
                ;;
            --keep-pvc)
                KEEP_PVC="true"
                shift
                ;;
            --cleanup-images)
                CLEANUP_IMAGES="true"
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
                echo "  --timeout TIMEOUT            Uninstall timeout (default: 5m)"
                echo "  --keep-namespace             Don't delete the namespace"
                echo "  --keep-pvc                   Don't delete PersistentVolumeClaims"
                echo "  --cleanup-images             Also remove Docker images"
                echo "  --dry-run                    Perform a dry run"
                echo "  --force                      Force cleanup even if Helm fails"
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
    print_header "🗑️  HOTEL RESERVATION SYSTEM - HELM UNINSTALL"
    
    parse_args "$@"
    
    # Show configuration
    print_status $CYAN "📋 Uninstall Configuration:"
    print_status $CYAN "   Namespace: $NAMESPACE"
    print_status $CYAN "   Release Name: $RELEASE_NAME"
    print_status $CYAN "   Keep Namespace: $KEEP_NAMESPACE"
    print_status $CYAN "   Keep PVCs: $KEEP_PVC"
    print_status $CYAN "   Cleanup Images: ${CLEANUP_IMAGES:-false}"
    print_status $CYAN "   Dry Run: $DRY_RUN"
    print_status $CYAN "   Force: $FORCE"
    echo ""
    
    check_release_exists
    show_current_release
    show_resources_to_remove
    
    # Confirm uninstall unless dry-run
    if [ "$DRY_RUN" = "false" ]; then
        print_status $RED "⚠️  This will permanently delete the Hotel Reservation System deployment!"
        read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status $YELLOW "Uninstall cancelled by user"
            exit 0
        fi
    fi
    
    local start_time=$(date +%s)
    
    uninstall_helm_release
    wait_for_deletion
    cleanup_pvcs
    cleanup_namespace
    cleanup_docker_images
    verify_cleanup
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ "$DRY_RUN" = "true" ]; then
        print_status $GREEN "🎉 Dry run uninstall completed successfully in ${duration} seconds!"
    else
        print_status $GREEN "🎉 Uninstall completed successfully in ${duration} seconds!"
        print_status $CYAN "📚 The Hotel Reservation System has been removed from your cluster."
        
        if [ "$KEEP_PVC" = "true" ]; then
            print_status $YELLOW "⚠️  PVCs were preserved. To remove them manually:"
            print_status $YELLOW "   kubectl delete pvc --all -n $NAMESPACE"
        fi
        
        if [ "$KEEP_NAMESPACE" = "true" ]; then
            print_status $YELLOW "⚠️  Namespace was preserved. To remove it manually:"
            print_status $YELLOW "   kubectl delete namespace $NAMESPACE"
        fi
    fi
}

# Run main function
main "$@"
