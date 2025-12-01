#!/usr/bin/env python3

import subprocess
import os
import datetime
import sys

def run_command(command, description, log_file):
    """Executa um comando e registra a saída"""
    print(f"\n=== {description} ===")
    
    with open(log_file, 'a', encoding='utf-8') as f:
        f.write(f"\n=== {description} ===\n")
        f.flush()
        
        try:
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Ler e escrever a saída em tempo real
            for line in process.stdout:
                print(line, end='')
                f.write(line)
                f.flush()
            
            process.wait()
            
            if process.returncode != 0:
                print(f"AVISO: Comando retornou código {process.returncode}")
                
        except Exception as e:
            error_msg = f"ERRO ao executar comando: {e}\n"
            print(error_msg)
            f.write(error_msg)

def main():
    # Configurar arquivo de log
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = f"ocp_debug_{timestamp}.txt"
    
    # Configurar KUBECONFIG
    kubeconfig_path = "/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig"
    os.environ['KUBECONFIG'] = kubeconfig_path
    
    print(f"Iniciando coleta de informações do OpenShift")
    print(f"Arquivo de log: {log_file}")
    
    # Verificar se o KUBECONFIG existe
    if not os.path.exists(kubeconfig_path):
        print(f"ERRO: Arquivo KUBECONFIG não encontrado: {kubeconfig_path}")
        sys.exit(1)
    
    # Executar comandos
    commands = [
        ("oc adm must-gather --image=registry.redhat.io/container-native-virtualization/cnv-must-gather-rhel9:v4.16.21", 
         "Must-Gather CNV"),
        ("oc adm must-gather", 
         "Must-Gather Padrão"),
        ("oc get co", 
         "Status dos Operadores"),
        ("oc get pods -n openshift-etcd", 
         "Pods do etcd"),
        ("oc -n openshift-etcd logs etcd-master-0.ocp.embasanet.ba.gov.br", 
         "Logs do etcd"),
        ("oc get co network -o yaml", 
         "Operador de Rede (YAML)")
    ]
    
    # Escrever cabeçalho
    with open(log_file, 'w', encoding='utf-8') as f:
        f.write(f"Coleta de Informações OpenShift\n")
        f.write(f"Data/Hora: {datetime.datetime.now()}\n")
        f.write(f"KUBECONFIG: {kubeconfig_path}\n")
    
    # Executar todos os comandos
    for command, description in commands:
        run_command(command, description, log_file)
    
    print(f"\nColeta concluída! Arquivo salvo em: {log_file}")

if __name__ == "__main__":
    main()