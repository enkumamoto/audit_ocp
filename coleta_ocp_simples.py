#!/usr/bin/env python3

import subprocess
import os
import shutil
import sys
import datetime

KUBECONFIG_PATH = "/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig"
COMMAND_TIMEOUT = 600  # segundos


def run(cmd, timeout=COMMAND_TIMEOUT):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return None


def quick_collect():
    """Versão simplificada da coleta"""
    if shutil.which("oc") is None:
        print("ERRO: binário 'oc' não encontrado no PATH")
        sys.exit(1)

    if not os.path.exists(KUBECONFIG_PATH):
        print(f"ERRO: Arquivo KUBECONFIG não encontrado: {KUBECONFIG_PATH}")
        sys.exit(1)

    os.environ['KUBECONFIG'] = KUBECONFIG_PATH

    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    log_filename = f"ocp_quick_{timestamp}.txt"

    commands = [
        ("=== MUST-GATHER CNV ===",
         ["oc", "adm", "must-gather", "--image=registry.redhat.io/container-native-virtualization/cnv-must-gather-rhel9:v4.16.21"]),
        ("=== OPERADORES ===", ["oc", "get", "co"]),
        ("=== ETCD PODS ===", ["oc", "get", "pods", "-n", "openshift-etcd"]),
        ("=== NETWORK OPERATOR ===", ["oc", "get", "co", "network", "-o", "yaml"]),
        ("=== Coletando informações do Uso de disco ===", ["oc", "project", "openshift-logging"]),
    ]

    with open(log_filename, 'w', encoding='utf-8') as f:
        f.write(f"Coleta Rápida - {datetime.datetime.now()}\n")

        try:
            for label, cmd in commands:
                print(label)
                f.write(f"\n{label}\n")
                result = run(cmd)
                if result is None:
                    msg = f"ERRO: comando excedeu timeout de {COMMAND_TIMEOUT}s\n"
                    f.write(msg)
                    print(msg, end='')
                    continue
                f.write(result.stdout)
                if result.stderr:
                    f.write(f"ERROS: {result.stderr}\n")
                if result.returncode != 0:
                    f.write(f"AVISO: comando retornou código {result.returncode}\n")
                print(f"Executado: {cmd[0]}")

            pods_result = run(["oc", "get", "pods", "-l", "component=elasticsearch", "-o", "name"])
            pods = pods_result.stdout.split() if pods_result else []
            for pod in pods:
                f.write(f"### {pod} ###\n")
                df_result = run(["oc", "-c", "elasticsearch", "exec", pod, "--", "df", "-kh"])
                if df_result is None:
                    f.write(f"ERRO: comando excedeu timeout de {COMMAND_TIMEOUT}s\n")
                    continue
                for line in df_result.stdout.splitlines():
                    if "persistent" in line:
                        f.write(line + "\n")
        except KeyboardInterrupt:
            print("\nColeta interrompida pelo usuário")
            f.write("\nColeta interrompida pelo usuário\n")
            sys.exit(130)

    print(f"Concluído: {log_filename}")


if __name__ == "__main__":
    quick_collect()
