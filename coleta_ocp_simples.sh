#!/bin/bash

# Script simplificado de coleta
set -uo pipefail

LOG_FILE="ocp_quick_$(date +%Y%m%d_%H%M%S).txt"
KUBECONFIG_PATH="/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig"
CMD_TIMEOUT="${CMD_TIMEOUT:-600}"

trap 'echo "Coleta interrompida pelo usuário" >> "$LOG_FILE"; exit 130' INT

if ! command -v oc >/dev/null 2>&1; then
    echo "ERRO: binário 'oc' não encontrado no PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

if [ ! -f "$KUBECONFIG" ]; then
    echo "ERRO: Arquivo KUBECONFIG não encontrado: $KUBECONFIG"
    exit 1
fi

{
    echo "Coleta Rápida - $(date)"

    echo "=== MUST-GATHER CNV ==="
    timeout "$CMD_TIMEOUT" oc adm must-gather --image=registry.redhat.io/container-native-virtualization/cnv-must-gather-rhel9:v4.16.21 || echo "AVISO: comando retornou código $? ou excedeu timeout"

    echo "=== OPERADORES ==="
    timeout "$CMD_TIMEOUT" oc get co || echo "AVISO: comando retornou código $? ou excedeu timeout"

    echo "=== ETCD PODS ==="
    timeout "$CMD_TIMEOUT" oc get pods -n openshift-etcd || echo "AVISO: comando retornou código $? ou excedeu timeout"

    echo "=== NETWORK OPERATOR ==="
    timeout "$CMD_TIMEOUT" oc get co network -o yaml || echo "AVISO: comando retornou código $? ou excedeu timeout"
} > "$LOG_FILE" 2>&1

echo "Concluído: $LOG_FILE"
