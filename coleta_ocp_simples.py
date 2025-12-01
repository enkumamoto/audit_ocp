#!/usr/bin/env python3

import subprocess
import os
import datetime

def quick_collect():
    """Versão simplificada da coleta"""
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = f"ocp_quick_{timestamp}.txt"
    
    # Configurar KUBECONFIG
    os.environ['KUBECONFIG'] = "/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig"
    
    commands = [
        "echo '=== MUST-GATHER CNV ==='",
        "oc adm must-gather --image=registry.redhat.io/container-native-virtualization/cnv-must-gather-rhel9:v4.16.21",
        "echo '=== OPERADORES ==='",
        "oc get co",
        "echo '=== ETCD PODS ==='", 
        "oc get pods -n openshift-etcd",
        "echo '=== NETWORK OPERATOR ==='",
        "oc get co network -o yaml",
        "echo '=== Coletando informações do Uso de disco ==='",
        "oc project openshift-logging",
        "for pod in $(oc get pods -l component=elasticsearch -o name); do echo '### $pod ###' ;oc -c elasticsearch exec $pod -- df -kh |  grep persistent ; done"
    ]
    
    # Executar todos os comandos e salvar em arquivo
    with open(log_file, 'w', encoding='utf-8') as f:
        f.write(f"Coleta Rápida - {datetime.datetime.now()}\n")
        
        for cmd in commands:
            try:
                if cmd.startswith('echo'):
                    # Comando echo especial
                    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                    f.write(result.stdout)
                    print(result.stdout.strip())
                else:
                    # Comando oc
                    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                    f.write(result.stdout)
                    if result.stderr:
                        f.write(f"ERROS: {result.stderr}\n")
                    
                    print(f"Executado: {cmd.split()[0]}")
                    
            except Exception as e:
                f.write(f"ERRO ao executar {cmd}: {e}\n")
    
    print(f"Concluído: {log_file}")

if __name__ == "__main__":
    quick_collect()