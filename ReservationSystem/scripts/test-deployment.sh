#!/bin/bash

# Test Deployment Script for Hotel Reservation System
# This script performs comprehensive testing of the deployed system

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
TIMEOUT=${TIMEOUT:-"300"}
VERBOSE=${VERBOSE:-"false"}

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

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

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    print_status $YELLOW "🧪 Testing: $test_name"
    
    if [ "$VERBOSE" = "true" ]; then
        print_status $CYAN "   Command: $test_command"
    fi
    
    local start_time=$(date +%s)
    local result
    
    if result=$(eval "$test_command" 2>&1); then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        if [ -z "$expected_result" ] || echo "$result" | grep -q "$expected_result"; then
            print_status $GREEN "   ✅ PASSED (${duration}s)"
            ((TESTS_PASSED++))
            
            if [ "$VERBOSE" = "true" ] && [ ! -z "$result" ]; then
                echo "$result" | head -3 | sed 's/^/      /'
            fi
        else
            print_status $RED "   ❌ FAILED - Expected: $expected_result"
            ((TESTS_FAILED++))
            FAILED_TESTS+=("$test_name")
            
            if [ "$VERBOSE" = "true" ]; then
                echo "$result" | head -5 | sed 's/^/      /'
            fi
        fi
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        print_status $RED "   ❌ FAILED (${duration}s)"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
        
        if [ "$VERBOSE" = "true" ]; then
            echo "$result" | head -5 | sed 's/^/      /'
        fi
    fi
}

# Function to test Helm release
test_helm_release() {
    print_status $CYAN "🎯 Testing Helm Release"
    
    run_test "Helm release exists" \
        "helm list -n $NAMESPACE | grep $RELEASE_NAME" \
        "$RELEASE_NAME"
    
    run_test "Helm release status" \
        "helm status $RELEASE_NAME -n $NAMESPACE" \
        "STATUS: deployed"
}

# Function to test Kubernetes resources
test_kubernetes_resources() {
    print_status $CYAN "🎯 Testing Kubernetes Resources"
    
    # Test namespace
    run_test "Namespace exists" \
        "kubectl get namespace $NAMESPACE" \
        "$NAMESPACE"
    
    # Test deployments
    run_test "All deployments ready" \
        "kubectl get deployments -n $NAMESPACE --no-headers | awk '{if(\$2 != \$4) exit 1}'" \
        ""
    
    # Test statefulsets
    run_test "All statefulsets ready" \
        "kubectl get statefulsets -n $NAMESPACE --no-headers | awk '{if(\$2 != \$3) exit 1}'" \
        ""
    
    # Test pods
    run_test "All pods running" \
        "kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running --no-headers | wc -l" \
        "0"
    
    # Test services
    run_test "All services have endpoints" \
        "kubectl get endpoints -n $NAMESPACE --no-headers | awk '{if(\$2 == \"<none>\") exit 1}'" \
        ""
}

# Function to test database connectivity
test_database_connectivity() {
    print_status $CYAN "🎯 Testing Database Connectivity"
    
    # Test PostgreSQL Auth
    run_test "PostgreSQL Auth connectivity" \
        "kubectl exec -n $NAMESPACE deployment/auth-service -- pg_isready -h postgres-auth -p 5432 -U authuser" \
        "accepting connections"
    
    # Test PostgreSQL Booking
    run_test "PostgreSQL Booking connectivity" \
        "kubectl exec -n $NAMESPACE deployment/booking-service -- python -c \"import psycopg2; conn = psycopg2.connect(host='postgres-booking', port=5432, user='bookinguser', password='bookingpass', database='bookingdb'); print('Connected')\"" \
        "Connected"
    
    # Test PostgreSQL Payment
    run_test "PostgreSQL Payment connectivity" \
        "kubectl exec -n $NAMESPACE deployment/payment-service -- nc -z postgres-payment 5432" \
        ""
    
    # Test MongoDB
    run_test "MongoDB connectivity" \
        "kubectl exec -n $NAMESPACE deployment/search-service -- mongosh --host mongodb:27017 --eval \"db.adminCommand('ping')\"" \
        "ok"
    
    # Test Redis
    run_test "Redis connectivity" \
        "kubectl exec -n $NAMESPACE deployment/search-service -- redis-cli -h redis -p 6379 ping" \
        "PONG"
}

# Function to test message brokers
test_message_brokers() {
    print_status $CYAN "🎯 Testing Message Brokers"
    
    # Test Kafka
    run_test "Kafka broker connectivity" \
        "kubectl exec -n $NAMESPACE statefulset/kafka -- kafka-broker-api-versions --bootstrap-server localhost:9092" \
        "kafka"
    
    # Test RabbitMQ
    run_test "RabbitMQ connectivity" \
        "kubectl exec -n $NAMESPACE statefulset/rabbitmq -- rabbitmq-diagnostics check_port_connectivity" \
        ""
    
    # Test RabbitMQ Management
    run_test "RabbitMQ Management API" \
        "kubectl exec -n $NAMESPACE statefulset/rabbitmq -- curl -s -u admin:admin123 http://localhost:15672/api/overview" \
        "management_version"
}

# Function to test service endpoints
test_service_endpoints() {
    print_status $CYAN "🎯 Testing Service Endpoints"
    
    # Test Gateway health
    run_test "Gateway health endpoint" \
        "kubectl exec -n $NAMESPACE deployment/gateway -- curl -s http://localhost:9000/health" \
        "status"
    
    # Test Auth Service health
    run_test "Auth Service health endpoint" \
        "kubectl exec -n $NAMESPACE deployment/auth-service -- curl -s http://localhost:8080/actuator/health" \
        "UP"
    
    # Test Search Service health
    run_test "Search Service health endpoint" \
        "kubectl exec -n $NAMESPACE deployment/search-service -- curl -s http://localhost:8081/health" \
        "status"
    
    # Test Booking Service health
    run_test "Booking Service health endpoint" \
        "kubectl exec -n $NAMESPACE deployment/booking-service -- curl -s http://localhost:8000/health" \
        "status"
    
    # Test Payment Service health
    run_test "Payment Service health endpoint" \
        "kubectl exec -n $NAMESPACE deployment/payment-service -- curl -s http://localhost:8082/health" \
        "status"
    
    # Test Notification Service health
    run_test "Notification Service health endpoint" \
        "kubectl exec -n $NAMESPACE deployment/notification-service -- curl -s http://localhost:8083/health" \
        "status"
}

# Function to test API functionality
test_api_functionality() {
    print_status $CYAN "🎯 Testing API Functionality"
    
    # Port forward to gateway for testing
    print_status $YELLOW "Setting up port-forward for API testing..."
    kubectl port-forward -n "$NAMESPACE" service/gateway 9000:9000 &
    local port_forward_pid=$!
    
    # Wait for port-forward to be ready
    sleep 5
    
    # Test API endpoints
    run_test "Gateway API root endpoint" \
        "curl -s http://localhost:9000/" \
        "Hotel Reservation System"
    
    run_test "Search hotels API" \
        "curl -s http://localhost:9000/api/search/hotels" \
        "hotels"
    
    run_test "Auth login API" \
        "curl -s -X POST http://localhost:9000/api/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"a@a.com\",\"password\":\"123456\"}'" \
        "token"
    
    # Cleanup port-forward
    kill $port_forward_pid 2>/dev/null || true
    wait $port_forward_pid 2>/dev/null || true
}

# Function to test resource usage
test_resource_usage() {
    print_status $CYAN "🎯 Testing Resource Usage"
    
    # Test CPU usage
    run_test "CPU usage within limits" \
        "kubectl top pods -n $NAMESPACE --no-headers | awk '{if(\$2 > 1000) exit 1}'" \
        ""
    
    # Test memory usage
    run_test "Memory usage within limits" \
        "kubectl top pods -n $NAMESPACE --no-headers | awk '{gsub(/Mi/, \"\", \$3); if(\$3 > 2000) exit 1}'" \
        ""
    
    # Test persistent volumes
    run_test "PVC usage reasonable" \
        "kubectl get pvc -n $NAMESPACE --no-headers | awk '{gsub(/Gi/, \"\", \$4); if(\$4 > 50) exit 1}'" \
        ""
}

# Function to test scaling
test_scaling() {
    print_status $CYAN "🎯 Testing Scaling Capabilities"
    
    # Test HPA if enabled
    local hpa_count=$(kubectl get hpa -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
    if [ "$hpa_count" -gt 0 ]; then
        run_test "HPA configured" \
            "kubectl get hpa -n $NAMESPACE" \
            "TARGETS"
    fi
    
    # Test manual scaling
    run_test "Manual scaling test" \
        "kubectl scale deployment gateway -n $NAMESPACE --replicas=3 && sleep 10 && kubectl get deployment gateway -n $NAMESPACE -o jsonpath='{.status.readyReplicas}'" \
        "3"
    
    # Scale back
    kubectl scale deployment gateway -n "$NAMESPACE" --replicas=2 >/dev/null 2>&1 || true
}

# Function to generate test report
generate_report() {
    print_header "📊 TEST REPORT"
    
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local success_rate=0
    
    if [ "$total_tests" -gt 0 ]; then
        success_rate=$(( (TESTS_PASSED * 100) / total_tests ))
    fi
    
    print_status $CYAN "📈 Test Summary:"
    print_status $GREEN "   ✅ Passed: $TESTS_PASSED"
    print_status $RED "   ❌ Failed: $TESTS_FAILED"
    print_status $CYAN "   📊 Total: $total_tests"
    print_status $CYAN "   🎯 Success Rate: ${success_rate}%"
    
    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        echo ""
        print_status $RED "❌ Failed Tests:"
        for test in "${FAILED_TESTS[@]}"; do
            print_status $RED "   - $test"
        done
    fi
    
    echo ""
    if [ "$TESTS_FAILED" -eq 0 ]; then
        print_status $GREEN "🎉 All tests passed! The deployment is healthy."
        return 0
    else
        print_status $RED "💥 Some tests failed. Please check the deployment."
        return 1
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
            --verbose)
                VERBOSE="true"
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --namespace NAMESPACE        Kubernetes namespace (default: hotel-reservation)"
                echo "  --release-name NAME          Helm release name (default: hotel-reservation)"
                echo "  --timeout TIMEOUT            Test timeout in seconds (default: 300)"
                echo "  --verbose                    Show detailed test output"
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
    print_header "🧪 HOTEL RESERVATION SYSTEM - DEPLOYMENT TESTING"
    
    parse_args "$@"
    
    # Show configuration
    print_status $CYAN "📋 Test Configuration:"
    print_status $CYAN "   Namespace: $NAMESPACE"
    print_status $CYAN "   Release Name: $RELEASE_NAME"
    print_status $CYAN "   Timeout: ${TIMEOUT}s"
    print_status $CYAN "   Verbose: $VERBOSE"
    echo ""
    
    local start_time=$(date +%s)
    
    # Run test suites
    test_helm_release
    test_kubernetes_resources
    test_database_connectivity
    test_message_brokers
    test_service_endpoints
    test_api_functionality
    test_resource_usage
    test_scaling
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    print_status $CYAN "⏱️  Total test duration: ${duration} seconds"
    
    # Generate and display report
    if generate_report; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
