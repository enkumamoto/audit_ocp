#!/bin/bash
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PASSED=0
FAILED=0

test_case() {
    local name="$1"
    local result="$2"
    if [ "$result" -eq 0 ]; then
        echo "✓ $name"
        ((PASSED++))
    else
        echo "✗ $name"
        ((FAILED++))
    fi
}

echo "========== TESTES DE INTEGRIDADE =========="
echo ""

# T1: Contar comandos (tuplas) em completo.py
echo "1. Validando completo.py e completo.sh..."
COMPLETO_PY_COMMANDS=$(grep -cE '^\s+\(\[' coleta_ocp_completo.py)
echo "   - Comandos em completo.py: $COMPLETO_PY_COMMANDS"
test_case "completo.py tem 7 comandos" $([ "$COMPLETO_PY_COMMANDS" -eq 7 ] && echo 0 || echo 1)

# T2: Contar seções em completo.sh
COMPLETO_SH_SECTIONS=$(grep -cE '===\s+[0-9]\.' coleta_ocp_completo.sh)
echo "   - Seções em completo.sh: $COMPLETO_SH_SECTIONS"
test_case "completo.sh tem 8 seções numeradas" $([ "$COMPLETO_SH_SECTIONS" -eq 8 ] && echo 0 || echo 1)

# T3: Must-gather padrão em completo.py e completo.sh
echo ""
echo "2. Validando must-gather padrão..."
grep -q 'Must-Gather Padrão' coleta_ocp_completo.py
test_case "completo.py tem must-gather padrão" $?

grep -q 'must-gather padrão' coleta_ocp_completo.sh
test_case "completo.sh tem must-gather padrão" $?

# T5: Ausência de must-gather padrão em simples.py e simples.sh
grep -q 'Must-Gather Padrão\|must-gather padrão' coleta_ocp_simples.py && TEST5=1 || TEST5=0
test_case "simples.py NÃO tem must-gather padrão" $TEST5

grep -q 'must-gather padrão' coleta_ocp_simples.sh && TEST6=1 || TEST6=0
test_case "simples.sh NÃO tem must-gather padrão" $TEST6

# T7: Logs do etcd em completo.py e completo.sh
echo ""
echo "3. Validando logs do etcd..."
grep -q 'Logs do etcd' coleta_ocp_completo.py
test_case "completo.py tem logs do etcd" $?

grep -q 'logs do etcd' coleta_ocp_completo.sh
test_case "completo.sh tem logs do etcd" $?

# T9: Ausência de logs do etcd em simples.py e simples.sh
! grep -q 'Logs do etcd' coleta_ocp_simples.py
test_case "simples.py NÃO tem logs do etcd" $?

! grep -q 'ETCD.*LOGS\|logs do etcd' coleta_ocp_simples.sh
test_case "simples.sh NÃO tem logs do etcd" $?

# T11-T13: Elasticsearch em completo.py e completo.sh (presente), ausente em simples.*
echo ""
echo "4. Validando Elasticsearch..."
grep -q 'Elasticsearch' coleta_ocp_completo.py
test_case "completo.py tem Elasticsearch" $?

grep -q 'Elasticsearch' coleta_ocp_completo.sh
test_case "completo.sh tem Elasticsearch" $?

! grep -q 'Elasticsearch' coleta_ocp_simples.py
test_case "simples.py NÃO tem Elasticsearch" $?

! grep -q 'Elasticsearch' coleta_ocp_simples.sh
test_case "simples.sh NÃO tem Elasticsearch" $?

# T14-T17: Status dos operadores em todos os scripts
echo ""
echo "5. Validando operadores (oc get co)..."
grep -q 'Status dos Operadores' coleta_ocp_completo.py
test_case "completo.py tem operadores" $?

grep -q 'operadores' coleta_ocp_completo.sh
test_case "completo.sh tem operadores" $?

grep -q 'OPERADORES' coleta_ocp_simples.py
test_case "simples.py tem operadores" $?

grep -q 'OPERADORES' coleta_ocp_simples.sh
test_case "simples.sh tem operadores" $?

# T18-T21: Pods do etcd em todos os scripts
echo ""
echo "6. Validando pods do etcd (oc get pods -n openshift-etcd)..."
grep -q 'Pods do etcd' coleta_ocp_completo.py
test_case "completo.py tem pods do etcd" $?

grep -q 'pods do etcd' coleta_ocp_completo.sh
test_case "completo.sh tem pods do etcd" $?

grep -q 'ETCD PODS' coleta_ocp_simples.py
test_case "simples.py tem pods do etcd" $?

grep -q 'ETCD PODS' coleta_ocp_simples.sh
test_case "simples.sh tem pods do etcd" $?

# T22-T25: Network em todos os scripts
echo ""
echo "7. Validando operador de rede (oc get co network)..."
grep -q 'Operador de Rede' coleta_ocp_completo.py
test_case "completo.py tem operador de rede" $?

grep -q 'network' coleta_ocp_completo.sh
test_case "completo.sh tem operador de rede" $?

grep -q 'NETWORK' coleta_ocp_simples.py
test_case "simples.py tem operador de rede" $?

grep -q 'NETWORK' coleta_ocp_simples.sh
test_case "simples.sh tem operador de rede" $?

# T26-T29: CNV em todos os scripts
echo ""
echo "8. Validando must-gather CNV..."
grep -q 'Must-Gather CNV' coleta_ocp_completo.py
test_case "completo.py tem CNV" $?

grep -q 'CNV' coleta_ocp_completo.sh
test_case "completo.sh tem CNV" $?

grep -q 'MUST-GATHER CNV' coleta_ocp_simples.py
test_case "simples.py tem CNV" $?

grep -q 'CNV' coleta_ocp_simples.sh
test_case "simples.sh tem CNV" $?

# T30-T33: Validação de KUBECONFIG e timeout
echo ""
echo "9. Validando KUBECONFIG e timeout..."
grep -q 'KUBECONFIG_PATH' coleta_ocp_completo.py
test_case "completo.py valida KUBECONFIG" $?

grep -q 'KUBECONFIG_PATH' coleta_ocp_completo.sh
test_case "completo.sh valida KUBECONFIG" $?

grep -q 'COMMAND_TIMEOUT' coleta_ocp_completo.py
test_case "completo.py tem timeout" $?

grep -q 'CMD_TIMEOUT' coleta_ocp_completo.sh
test_case "completo.sh tem timeout" $?

# Resumo
echo ""
echo "========== RESUMO =========="
echo "Passou: $PASSED"
echo "Falhou: $FAILED"

if [ "$FAILED" -eq 0 ]; then
    echo "✓ Todos os testes passaram!"
    exit 0
else
    echo "✗ Alguns testes falharam"
    exit 1
fi
