#!/bin/bash

# Script completo de coleta de informações do OpenShift
set -e

LOG_FILE="ocp_debug_$(date +%Y%m%d_%H%M%S).txt"
echo "Iniciando coleta de informações do OpenShift - $(date)" | tee -a "$LOG_FILE"

# Exportar KUBECONFIG
echo -e "\n=== 1. Configurando KUBECONFIG ===" | tee -a "$LOG_FILE"
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
echo "KUBECONFIG definido para: $KUBECONFIG" | tee -a "$LOG_FILE"

# Verificar se o arquivo existe
if [ ! -f "$KUBECONFIG" ]; then
    echo "ERRO: Arquivo KUBECONFIG não encontrado: $KUBECONFIG" | tee -a "$LOG_FILE"
    exit 1
fi

# Executar must-gather CNV
echo -e "\n=== 2. Executando must-gather CNV ===" | tee -a "$LOG_FILE"
oc adm must-gather --image=registry.redhat.io/container-native-virtualization/cnv-must-gather-rhel9:v4.16.21 2>&1 | tee -a "$LOG_FILE"

# Executar must-gather padrão
echo -e "\n=== 3. Executando must-gather padrão ===" | tee -a "$LOG_FILE"
oc adm must-gather 2>&1 | tee -a "$LOG_FILE"

# Coletar informações dos operadores
echo -e "\n=== 4. Coletando status dos operadores ===" | tee -a "$LOG_FILE"
oc get co 2>&1 | tee -a "$LOG_FILE"

# Coletar informações dos pods do etcd
echo -e "\n=== 5. Coletando pods do etcd ===" | tee -a "$LOG_FILE"
oc get pods -n openshift-etcd 2>&1 | tee -a "$LOG_FILE"

# Coletar logs do etcd
echo -e "\n=== 6. Coletando logs do etcd ===" | tee -a "$LOG_FILE"
oc -n openshift-etcd logs etcd-master-0.ocp.embasanet.ba.gov.br 2>&1 | tee -a "$LOG_FILE"

# Coletar informações detalhadas do operador de rede
echo -e "\n=== 7. Coletando informações do operador de rede ===" | tee -a "$LOG_FILE"
oc get co network -o yaml 2>&1 | tee -a "$LOG_FILE"

echo -e "\nColeta concluída! Arquivo salvo em: $LOG_FILE" | tee -a "$LOG_FILE"

# Checagem de uso de disco (ElasticSearch)
echo -e "\n=== 7. Coletando informações do Uso de disco (Elasticsearch) ===" | tee -a "$LOG_FILE"
oc project openshift-logging

for pod in $(oc get pods -l component=elasticsearch -o name); do echo "### $pod ###" ;oc -c elasticsearch exec $pod -- df -kh |  grep persistent ; done

echo -e "\nColeta concluída! Arquivo salvo em: $LOG_FILE" | tee -a "$LOG_FILE"