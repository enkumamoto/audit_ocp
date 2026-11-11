#!/bin/bash

# Script completo de coleta de informações do OpenShift
set -uo pipefail

LOG_FILE="ocp_debug_$(date +%Y%m%d_%H%M%S).txt"
KUBECONFIG_PATH="/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig"
OCP_DOMAIN="${OCP_DOMAIN:-}"   # ex: export OCP_DOMAIN=ocp.exemplo.com.br
CMD_TIMEOUT="${CMD_TIMEOUT:-600}"

trap 'echo "Coleta interrompida pelo usuário" | tee -a "$LOG_FILE"; exit 130' INT

echo "Iniciando coleta de informações do OpenShift - $(date)" | tee -a "$LOG_FILE"

if ! command -v oc >/dev/null 2>&1; then
    echo "ERRO: binário 'oc' não encontrado no PATH" | tee -a "$LOG_FILE"
    exit 1
fi

echo -e "\n=== 1. Configurando KUBECONFIG ===" | tee -a "$LOG_FILE"
export KUBECONFIG="$KUBECONFIG_PATH"
echo "KUBECONFIG definido para: $KUBECONFIG" | tee -a "$LOG_FILE"

if [ ! -f "$KUBECONFIG" ]; then
    echo "ERRO: Arquivo KUBECONFIG não encontrado: $KUBECONFIG" | tee -a "$LOG_FILE"
    exit 1
fi

echo -e "\n=== 2. Executando must-gather CNV ===" | tee -a "$LOG_FILE"
timeout "$CMD_TIMEOUT" oc adm must-gather --image=registry.redhat.io/container-native-virtualization/cnv-must-gather-rhel9:v4.16.21 2>&1 | tee -a "$LOG_FILE"
STATUS=("${PIPESTATUS[@]}")
[ "${STATUS[0]}" -eq 0 ] || echo "AVISO: comando retornou código ${STATUS[0]} ou excedeu timeout" | tee -a "$LOG_FILE"

echo -e "\n=== 3. Executando must-gather padrão ===" | tee -a "$LOG_FILE"
timeout "$CMD_TIMEOUT" oc adm must-gather 2>&1 | tee -a "$LOG_FILE"
STATUS=("${PIPESTATUS[@]}")
[ "${STATUS[0]}" -eq 0 ] || echo "AVISO: comando retornou código ${STATUS[0]} ou excedeu timeout" | tee -a "$LOG_FILE"

echo -e "\n=== 4. Coletando status dos operadores ===" | tee -a "$LOG_FILE"
timeout "$CMD_TIMEOUT" oc get co 2>&1 | tee -a "$LOG_FILE"
STATUS=("${PIPESTATUS[@]}")
[ "${STATUS[0]}" -eq 0 ] || echo "AVISO: comando retornou código ${STATUS[0]} ou excedeu timeout" | tee -a "$LOG_FILE"

echo -e "\n=== 5. Coletando pods do etcd ===" | tee -a "$LOG_FILE"
timeout "$CMD_TIMEOUT" oc get pods -n openshift-etcd 2>&1 | tee -a "$LOG_FILE"
STATUS=("${PIPESTATUS[@]}")
[ "${STATUS[0]}" -eq 0 ] || echo "AVISO: comando retornou código ${STATUS[0]} ou excedeu timeout" | tee -a "$LOG_FILE"

echo -e "\n=== 6. Coletando logs do etcd ===" | tee -a "$LOG_FILE"
ETCD_POD=$(oc get pods -n openshift-etcd -o name 2>/dev/null | grep '^pod/etcd-' | grep -v guard | head -n1 | cut -d/ -f2)
if [ -z "$ETCD_POD" ] && [ -n "$OCP_DOMAIN" ]; then
    ETCD_POD="etcd-master-0.${OCP_DOMAIN}"
fi
if [ -z "$ETCD_POD" ]; then
    echo "ERRO: não foi possível determinar o pod etcd; defina OCP_DOMAIN ou ajuste manualmente" | tee -a "$LOG_FILE"
else
    timeout "$CMD_TIMEOUT" oc -n openshift-etcd logs "$ETCD_POD" 2>&1 | tee -a "$LOG_FILE"
    STATUS=("${PIPESTATUS[@]}")
    [ "${STATUS[0]}" -eq 0 ] || echo "AVISO: comando retornou código ${STATUS[0]} ou excedeu timeout" | tee -a "$LOG_FILE"
fi

echo -e "\n=== 7. Coletando informações do operador de rede ===" | tee -a "$LOG_FILE"
timeout "$CMD_TIMEOUT" oc get co network -o yaml 2>&1 | tee -a "$LOG_FILE"
STATUS=("${PIPESTATUS[@]}")
[ "${STATUS[0]}" -eq 0 ] || echo "AVISO: comando retornou código ${STATUS[0]} ou excedeu timeout" | tee -a "$LOG_FILE"

echo -e "\n=== 8. Coletando informações do Uso de disco (Elasticsearch) ===" | tee -a "$LOG_FILE"
CURRENT_PROJECT=$(oc project -q 2>/dev/null)
oc project openshift-logging 2>/dev/null

for pod in $(oc get pods -l component=elasticsearch -o name 2>/dev/null); do
    echo "### $pod ###" | tee -a "$LOG_FILE"
    timeout "$CMD_TIMEOUT" oc -c elasticsearch exec "$pod" -- df -kh 2>&1 | grep persistent | tee -a "$LOG_FILE"
done

oc project "$CURRENT_PROJECT" 2>/dev/null

echo -e "\nColeta concluída! Arquivo salvo em: $LOG_FILE" | tee -a "$LOG_FILE"
