#!/bin/bash

# Comprehensive Helm Deployment Script for Hotel Reservation System
# This script handles the complete deployment process including prerequisites, building, and deployment

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
NAMESPACE=${NAMESPACE:-"hotel-reservation"}
RELEASE_NAME=${RELEASE_NAME:-"hotel-reservation"}
CHART_PATH=${CHART_PATH:-"helm/hotel-reservation-system"}
VALUES_FILE=${VALUES_FILE:-""}
ENVIRONMENT=${ENVIRONMENT:-"development"}
TIMEOUT=${TIMEOUT:-"15m"}
BUILD_IMAGES=${BUILD_IMAGES:-"true"}
WAIT_FOR_READY=${WAIT_FOR_READY:-"true"}
DRY_RUN=${DRY_RUN:-"false"}

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

# Function to check prerequisites
check_prerequisites() {
    print_status $YELLOW "🔍 Checking prerequisites..."
    
    # Check if kubectl is installed and configured
    if ! command -v kubectl &> /dev/null; then
        print_status $RED "❌ kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_status $RED "❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    print_status $GREEN "✅ kubectl is configured and connected"
    
    # Check if Helm is installed
    if ! command -v helm &> /dev/null; then
        print_status $RED "❌ Helm is not installed. Please install Helm first."
        exit 1
    fi
    
    print_status $GREEN "✅ Helm is installed"
    
    # Check if Docker is running (if building images)
    if [ "$BUILD_IMAGES" = "true" ]; then
        if ! docker info &> /dev/null; then
            print_status $RED "❌ Docker is not running. Please start Docker first."
            exit 1
        fi
        print_status $GREEN "✅ Docker is running"
    fi
    
    # Check if chart directory exists
    if [ ! -d "$CHART_PATH" ]; then
        print_status $RED "❌ Helm chart not found at: $CHART_PATH"
        exit 1
    fi
    
    print_status $GREEN "✅ Helm chart found at: $CHART_PATH"
}

# Function to display configuration
display_config() {
    print_status $CYAN "📋 Deployment Configuration:"
    print_status $CYAN "   Namespace: $NAMESPACE"
    print_status $CYAN "   Release Name: $RELEASE_NAME"
    print_status $CYAN "   Chart Path: $CHART_PATH"
    print_status $CYAN "   Environment: $ENVIRONMENT"
    print_status $CYAN "   Values File: ${VALUES_FILE:-"(default)"}"
    print_status $CYAN "   Timeout: $TIMEOUT"
    print_status $CYAN "   Build Images: $BUILD_IMAGES"
    print_status $CYAN "   Wait for Ready: $WAIT_FOR_READY"
    print_status $CYAN "   Dry Run: $DRY_RUN"
    
    # Display cluster info
    local cluster_info=$(kubectl config current-context)
    print_status $CYAN "   Kubernetes Context: $cluster_info"
    echo ""
}

# Function to build Docker images
build_images() {
    if [ "$BUILD_IMAGES" = "true" ]; then
        print_status $YELLOW "🔨 Building Docker images..."
        
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

# Function to create namespace if it doesn't exist
create_namespace() {
    print_status $YELLOW "🏗️  Checking namespace: $NAMESPACE"
    
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        print_status $YELLOW "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
        print_status $GREEN "✅ Namespace created: $NAMESPACE"
    else
        print_status $GREEN "✅ Namespace already exists: $NAMESPACE"
    fi
}

# Function to validate Helm chart
validate_chart() {
    print_status $YELLOW "🔍 Validating Helm chart..."
    
    # Lint the chart
    if helm lint "$CHART_PATH"; then
        print_status $GREEN "✅ Helm chart validation passed"
    else
        print_status $RED "❌ Helm chart validation failed"
        exit 1
    fi
    
    # Template the chart to check for syntax errors
    local template_output="/tmp/helm-template-output.yaml"
    local helm_cmd="helm template $RELEASE_NAME $CHART_PATH --namespace $NAMESPACE"
    
    if [ ! -z "$VALUES_FILE" ]; then
        helm_cmd="$helm_cmd --values $VALUES_FILE"
    fi
    
    if $helm_cmd > "$template_output"; then
        print_status $GREEN "✅ Helm template generation successful"
        rm -f "$template_output"
    else
        print_status $RED "❌ Helm template generation failed"
        exit 1
    fi
}

# Function to deploy with Helm
deploy_helm() {
    print_status $YELLOW "🚀 Deploying with Helm..."
    
    local helm_cmd="helm upgrade --install $RELEASE_NAME $CHART_PATH"
    helm_cmd="$helm_cmd --namespace $NAMESPACE"
    helm_cmd="$helm_cmd --create-namespace"
    helm_cmd="$helm_cmd --timeout $TIMEOUT"
    
    if [ ! -z "$VALUES_FILE" ]; then
        helm_cmd="$helm_cmd --values $VALUES_FILE"
    fi
    
    # Set environment-specific values
    helm_cmd="$helm_cmd --set global.environment=$ENVIRONMENT"
    
    if [ "$WAIT_FOR_READY" = "true" ]; then
        helm_cmd="$helm_cmd --wait"
    fi
    
    if [ "$DRY_RUN" = "true" ]; then
        helm_cmd="$helm_cmd --dry-run"
        print_status $YELLOW "🧪 Running in dry-run mode..."
    fi
    
    print_status $CYAN "Executing: $helm_cmd"
    
    if $helm_cmd; then
        if [ "$DRY_RUN" = "true" ]; then
            print_status $GREEN "✅ Dry run completed successfully"
        else
            print_status $GREEN "✅ Helm deployment completed successfully"
        fi
    else
        print_status $RED "❌ Helm deployment failed"
        exit 1
    fi
}

# Function to wait for pods to be ready
wait_for_pods() {
    if [ "$WAIT_FOR_READY" = "true" ] && [ "$DRY_RUN" = "false" ]; then
        print_status $YELLOW "⏳ Waiting for pods to be ready..."
        
        # Wait for all deployments to be ready
        if kubectl wait --for=condition=available --timeout=600s deployment --all -n "$NAMESPACE"; then
            print_status $GREEN "✅ All deployments are ready"
        else
            print_status $RED "❌ Some deployments failed to become ready"
            print_status $YELLOW "📊 Current pod status:"
            kubectl get pods -n "$NAMESPACE"
            exit 1
        fi
        
        # Wait for all StatefulSets to be ready
        if kubectl get statefulsets -n "$NAMESPACE" --no-headers | wc -l | grep -q "^[1-9]"; then
            if kubectl wait --for=condition=ready --timeout=600s pod -l app.kubernetes.io/component=database -n "$NAMESPACE"; then
                print_status $GREEN "✅ All StatefulSets are ready"
            else
                print_status $RED "❌ Some StatefulSets failed to become ready"
                exit 1
            fi
        fi
    fi
}

# Function to display deployment status
display_status() {
    if [ "$DRY_RUN" = "false" ]; then
        print_status $CYAN "📊 Deployment Status:"
        
        # Show Helm release status
        helm status "$RELEASE_NAME" -n "$NAMESPACE"
        
        echo ""
        print_status $CYAN "🏗️  Kubernetes Resources:"
        
        # Show pods
        print_status $YELLOW "Pods:"
        kubectl get pods -n "$NAMESPACE" -o wide
        
        echo ""
        # Show services
        print_status $YELLOW "Services:"
        kubectl get services -n "$NAMESPACE"
        
        echo ""
        # Show ingress if exists
        if kubectl get ingress -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l | grep -q "^[1-9]"; then
            print_status $YELLOW "Ingress:"
            kubectl get ingress -n "$NAMESPACE"
        fi
    fi
}

# Function to display access information
display_access_info() {
    if [ "$DRY_RUN" = "false" ]; then
        print_status $GREEN "🌐 Access Information:"
        
        # Get Gateway service info
        local gateway_service=$(kubectl get service -n "$NAMESPACE" -l app.kubernetes.io/name=gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
        
        if [ ! -z "$gateway_service" ]; then
            local service_type=$(kubectl get service "$gateway_service" -n "$NAMESPACE" -o jsonpath='{.spec.type}')
            local service_port=$(kubectl get service "$gateway_service" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}')
            
            case $service_type in
                "NodePort")
                    local node_port=$(kubectl get service "$gateway_service" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')
                    local node_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
                    if [ -z "$node_ip" ]; then
                        node_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
                    fi
                    print_status $CYAN "   Gateway URL: http://$node_ip:$node_port"
                    ;;
                "LoadBalancer")
                    print_status $YELLOW "   Waiting for LoadBalancer IP..."
                    local lb_ip=$(kubectl get service "$gateway_service" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
                    if [ ! -z "$lb_ip" ]; then
                        print_status $CYAN "   Gateway URL: http://$lb_ip:$service_port"
                    else
                        print_status $YELLOW "   LoadBalancer IP not yet assigned"
                    fi
                    ;;
                "ClusterIP")
                    print_status $CYAN "   Gateway Service: $gateway_service:$service_port (ClusterIP)"
                    print_status $YELLOW "   Use port-forward: kubectl port-forward -n $NAMESPACE service/$gateway_service 9000:$service_port"
                    ;;
            esac
        fi
        
        # Check for Ingress
        local ingress_name=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
        if [ ! -z "$ingress_name" ]; then
            local ingress_host=$(kubectl get ingress "$ingress_name" -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}')
            print_status $CYAN "   Ingress URL: http://$ingress_host"
        fi
        
        echo ""
        print_status $GREEN "🔐 Default Login Credentials:"
        print_status $CYAN "   Admin: admin@hotel.com / admin123"
        print_status $CYAN "   Customer: a@a.com / 123456"
    fi
}

# Function to cleanup on failure
cleanup_on_failure() {
    if [ "$?" -ne 0 ] && [ "$DRY_RUN" = "false" ]; then
        print_status $RED "💥 Deployment failed. Checking for cleanup..."
        
        # Show recent events
        print_status $YELLOW "📋 Recent events:"
        kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -10
        
        # Show failed pods
        print_status $YELLOW "❌ Failed pods:"
        kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Failed
        
        # Optionally rollback
        read -p "Do you want to rollback the release? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status $YELLOW "🔄 Rolling back..."
            helm rollback "$RELEASE_NAME" -n "$NAMESPACE"
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
            --chart-path)
                CHART_PATH="$2"
                shift 2
                ;;
            --values-file)
                VALUES_FILE="$2"
                shift 2
                ;;
            --environment)
                ENVIRONMENT="$2"
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
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --namespace NAMESPACE        Kubernetes namespace (default: hotel-reservation)"
                echo "  --release-name NAME          Helm release name (default: hotel-reservation)"
                echo "  --chart-path PATH            Path to Helm chart (default: helm/hotel-reservation-system)"
                echo "  --values-file FILE           Values file to use"
                echo "  --environment ENV            Environment (development/staging/production)"
                echo "  --timeout TIMEOUT            Deployment timeout (default: 15m)"
                echo "  --no-build                   Skip building Docker images"
                echo "  --no-wait                    Don't wait for pods to be ready"
                echo "  --dry-run                    Perform a dry run"
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
    # Set up error handling
    trap cleanup_on_failure ERR
    
    print_header "🚀 HOTEL RESERVATION SYSTEM - HELM DEPLOYMENT"
    
    parse_args "$@"
    check_prerequisites
    display_config
    
    local start_time=$(date +%s)
    
    build_images
    create_namespace
    validate_chart
    deploy_helm
    wait_for_pods
    display_status
    display_access_info
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ "$DRY_RUN" = "true" ]; then
        print_status $GREEN "🎉 Dry run completed successfully in ${duration} seconds!"
    else
        print_status $GREEN "🎉 Deployment completed successfully in ${duration} seconds!"
        print_status $CYAN "📚 Next steps:"
        print_status $CYAN "   1. Access the application using the URLs above"
        print_status $CYAN "   2. Monitor with: kubectl get pods -n $NAMESPACE -w"
        print_status $CYAN "   3. View logs with: kubectl logs -f deployment/gateway -n $NAMESPACE"
        print_status $CYAN "   4. Uninstall with: helm uninstall $RELEASE_NAME -n $NAMESPACE"
    fi
}

# Run main function
main "$@"
