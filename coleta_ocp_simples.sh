#!/bin/bash

# Script simplificado de coleta
LOG_FILE="ocp_quick_$(date +%Y%m%d_%H%M%S).txt"

export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

{
    echo "Coleta Rápida - $(date)"
    echo "=== MUST-GATHER CNV ==="
    oc adm must-gather --image=registry.redhat.io/container-native-virtualization/cnv-must-gather-rhel9:v4.16.21
    
    echo "=== OPERADORES ==="
    oc get co
    
    echo "=== ETCD PODS ==="
    oc get pods -n openshift-etcd
    
    echo "=== NETWORK OPERATOR ==="
    oc get co network -o yaml
} > "$LOG_FILE" 2>&1

echo "Concluído: $LOG_FILE"