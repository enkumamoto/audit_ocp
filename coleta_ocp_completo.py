#!/usr/bin/env python3

import subprocess
import os
import shutil
import sys
import time
import datetime
import select

KUBECONFIG_PATH = "/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig"
OCP_DOMAIN = os.environ.get("OCP_DOMAIN", "")  # ex: export OCP_DOMAIN=ocp.exemplo.com.br
COMMAND_TIMEOUT = 600  # segundos

def run_command(command, description, log_file, timeout=COMMAND_TIMEOUT):
    """Executa um comando (lista de args) e registra a saída em tempo real, com timeout."""
    header = f"\n=== {description} ===\n"
    print(header, end='')
    log_file.write(header)
    log_file.flush()

    process = None
    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )

        deadline = time.time() + timeout
        while process.poll() is None:
            remaining = deadline - time.time()
            if remaining <= 0:
                process.kill()
                msg = f"ERRO: comando excedeu timeout de {timeout}s e foi encerrado\n"
                print(msg, end='')
                log_file.write(msg)
                log_file.flush()
                break

            # Use select() com timeout curto para evitar travar em comandos silenciosos
            ready = select.select([process.stdout], [], [], min(1, remaining))
            if ready[0]:
                linha = process.stdout.readline()
                if linha:
                    print(linha, end='')
                    log_file.write(linha)
                    log_file.flush()

        process.wait()

        if process.returncode != 0:
            msg = f"AVISO: comando retornou código {process.returncode}\n"
            print(msg, end='')
            log_file.write(msg)

    except FileNotFoundError as e:
        msg = f"ERRO: comando não encontrado: {e}\n"
        print(msg, end='')
        log_file.write(msg)
    except KeyboardInterrupt:
        if process:
            process.kill()
        raise
    except Exception as e:
        msg = f"ERRO ao executar comando: {e}\n"
        print(msg, end='')
        log_file.write(msg)


def descobrir_pod_etcd():
    """Descobre dinamicamente o pod etcd; usa OCP_DOMAIN como fallback se a descoberta falhar."""
    try:
        result = subprocess.run(
            ["oc", "get", "pods", "-n", "openshift-etcd", "-o", "name"],
            capture_output=True, text=True, timeout=30
        )
        for line in result.stdout.splitlines():
            nome = line.strip().split("/")[-1]
            if nome.startswith("etcd-") and "guard" not in nome:
                return nome
    except Exception:
        pass

    if OCP_DOMAIN:
        return f"etcd-master-0.{OCP_DOMAIN}"
    return None


def main():
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    log_filename = f"ocp_debug_{timestamp}.txt"

    os.environ['KUBECONFIG'] = KUBECONFIG_PATH

    print("Iniciando coleta de informações do OpenShift")
    print(f"Arquivo de log: {log_filename}")

    if shutil.which("oc") is None:
        print("ERRO: binário 'oc' não encontrado no PATH")
        sys.exit(1)

    if not os.path.exists(KUBECONFIG_PATH):
        print(f"ERRO: Arquivo KUBECONFIG não encontrado: {KUBECONFIG_PATH}")
        sys.exit(1)

    pod_etcd = descobrir_pod_etcd()
    if pod_etcd is None:
        print("AVISO: não foi possível determinar o pod etcd; defina a variável de ambiente OCP_DOMAIN ou ajuste manualmente")

    commands = [
        (["oc", "adm", "must-gather", "--image=registry.redhat.io/container-native-virtualization/cnv-must-gather-rhel9:v4.16.21"],
         "Must-Gather CNV"),
        (["oc", "adm", "must-gather"],
         "Must-Gather Padrão"),
        (["oc", "get", "co"],
         "Status dos Operadores"),
        (["oc", "get", "pods", "-n", "openshift-etcd"],
         "Pods do etcd"),
        (["oc", "-n", "openshift-etcd", "logs", pod_etcd] if pod_etcd else None,
         "Logs do etcd"),
        (["oc", "get", "co", "network", "-o", "yaml"],
         "Operador de Rede (YAML)"),
        (["sh", "-c", "oc project openshift-logging && for pod in $(oc get pods -l component=elasticsearch -o name 2>/dev/null); do echo \"### $pod ###\" && oc -c elasticsearch exec $pod -- df -kh 2>&1 | grep persistent; done"],
         "Uso de disco (Elasticsearch)"),
    ]

    with open(log_filename, 'w', encoding='utf-8') as log_file:
        log_file.write("Coleta de Informações OpenShift\n")
        log_file.write(f"Data/Hora: {datetime.datetime.now()}\n")
        log_file.write(f"KUBECONFIG: {KUBECONFIG_PATH}\n")
        log_file.flush()

        try:
            for command, description in commands:
                if command is None:
                    msg = f"\n=== {description} ===\nERRO: pod etcd não identificado, comando ignorado\n"
                    print(msg, end='')
                    log_file.write(msg)
                    continue
                run_command(command, description, log_file)
        except KeyboardInterrupt:
            print("\nColeta interrompida pelo usuário")
            log_file.write("\nColeta interrompida pelo usuário\n")
            sys.exit(130)

    print(f"\nColeta concluída! Arquivo salvo em: {log_filename}")

if __name__ == "__main__":
    main()
