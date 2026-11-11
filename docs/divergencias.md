# Divergências Reais entre os 4 Scripts de Coleta

## Resumo das divergências

| Passo | completo.py | completo.sh | simples.py | simples.sh |
|-------|:-----------:|:-----------:|:----------:|:----------:|
| Must-gather CNV | ✔ | ✔ | ✔ | ✔ |
| Must-gather padrão | ✔ | ✔ | ✖ | ✖ |
| Status dos operadores | ✔ | ✔ | ✔ | ✔ |
| Pods do etcd | ✔ | ✔ | ✔ | ✔ |
| Logs do etcd | ✔ | ✔ | ✖ | ✖ |
| Operador de rede (YAML) | ✔ | ✔ | ✔ | ✔ |
| Disco do Elasticsearch | ✖ | ✔ | ✔ | ✖ |

---

## Análise detalhada por passo

### 1. Must-gather com imagem CNV (`--image=...cnv-must-gather-rhel9:v4.16.21`)

**Implementação:**
- `completo.py`: Linha 105-106, primeiro comando na lista
- `completo.sh`: Linha 30, seção "2. Executando must-gather CNV"
- `simples.py`: Linha 37, primeiro comando na lista
- `simples.sh`: Linha 28, dentro do bloco redirigido

**Conclusão:** ✔ **Presente em todos os 4 scripts**

Intencional. É o passo mais crítico e unificado em todas as versões.

---

### 2. Must-gather padrão (sem imagem customizada)

**Implementação:**
- `completo.py`: Linha 107-108, segundo comando na lista
  ```python
  (["oc", "adm", "must-gather"],
   "Must-Gather Padrão"),
  ```
- `completo.sh`: Linha 34, seção "3. Executando must-gather padrão"
  ```bash
  timeout "$CMD_TIMEOUT" oc adm must-gather 2>&1 | tee -a "$LOG_FILE"
  ```
- `simples.py`: **NÃO existe** — `commands` lista só tem 5 entradas (linhas 35-42), nenhuma é must-gather padrão
- `simples.sh`: **NÃO existe** — bloco redirigido (linhas 24-38) não inclui este comando

**Conclusão:** ✖ **Ausente em simples.py e simples.sh**

**Razão:** Intencional. A versão "simples" coleta apenas o must-gather CNV (mais leve), não o padrão (mais pesado). Objetivo: reduzir tempo de coleta para diagnóstico rápido.

---

### 3. Status dos operadores (`oc get co`)

**Implementação:**
- `completo.py`: Linha 109-110
  ```python
  (["oc", "get", "co"],
   "Status dos Operadores"),
  ```
- `completo.sh`: Linha 38
  ```bash
  timeout "$CMD_TIMEOUT" oc get co 2>&1 | tee -a "$LOG_FILE"
  ```
- `simples.py`: Linha 38
  ```python
  ("=== OPERADORES ===", ["oc", "get", "co"]),
  ```
- `simples.sh`: Linha 31
  ```bash
  timeout "$CMD_TIMEOUT" oc get co || echo "AVISO: comando retornou código $? ou excedeu timeout"
  ```

**Conclusão:** ✔ **Presente em todos os 4 scripts**

Intencional. Status dos operadores é informação crítica e rápida de coletar.

---

### 4. Pods do namespace etcd (`oc get pods -n openshift-etcd`)

**Implementação:**
- `completo.py`: Linha 111-112
  ```python
  (["oc", "get", "pods", "-n", "openshift-etcd"],
   "Pods do etcd"),
  ```
- `completo.sh`: Linha 42
  ```bash
  timeout "$CMD_TIMEOUT" oc get pods -n openshift-etcd 2>&1 | tee -a "$LOG_FILE"
  ```
- `simples.py`: Linha 39
  ```python
  ("=== ETCD PODS ===", ["oc", "get", "pods", "-n", "openshift-etcd"]),
  ```
- `simples.sh`: Linha 34
  ```bash
  timeout "$CMD_TIMEOUT" oc get pods -n openshift-etcd || echo "AVISO: comando retornou código $? ou excedeu timeout"
  ```

**Conclusão:** ✔ **Presente em todos os 4 scripts**

Intencional. Listagem dos pods é rápida e essencial para diagnóstico.

---

### 5. Logs do etcd (`oc -n openshift-etcd logs <pod>`)

**Implementação:**
- `completo.py`: Linha 113-114 (condicional)
  ```python
  (["oc", "-n", "openshift-etcd", "logs", pod_etcd] if pod_etcd else None,
   "Logs do etcd"),
  ```
  Pod é descoberto dinamicamente nas linhas 64-80. Se não encontrado e `OCP_DOMAIN` estiver definido, usa fallback `etcd-master-0.<domínio>`.

- `completo.sh`: Linha 45-55 (condicional)
  ```bash
  ETCD_POD=$(oc get pods -n openshift-etcd -o name 2>/dev/null | grep '^pod/etcd-' | grep -v guard | head -n1 | cut -d/ -f2)
  if [ -z "$ETCD_POD" ] && [ -n "$OCP_DOMAIN" ]; then
      ETCD_POD="etcd-master-0.${OCP_DOMAIN}"
  fi
  if [ -z "$ETCD_POD" ]; then
      echo "ERRO: não foi possível determinar o pod etcd; defina OCP_DOMAIN ou ajuste manualmente" | tee -a "$LOG_FILE"
  else
      timeout "$CMD_TIMEOUT" oc -n openshift-etcd logs "$ETCD_POD" 2>&1 | tee -a "$LOG_FILE"
  ```

- `simples.py`: **NÃO existe** — função `quick_collect()` não tem lógica para descoberta ou coleta de logs do etcd

- `simples.sh`: **NÃO existe** — bloco redirigido (linhas 24-38) não inclui este comando

**Conclusão:** ✖ **Ausente em simples.py e simples.sh**

**Razão:** Intencional. Logs do etcd podem ser muito voluminosos. A versão "simples" prioriza rapidez; logs são coletados na versão "completa".

---

### 6. Operador de Rede em YAML (`oc get co network -o yaml`)

**Implementação:**
- `completo.py`: Linha 115-116
  ```python
  (["oc", "get", "co", "network", "-o", "yaml"],
   "Operador de Rede (YAML)"),
  ```

- `completo.sh`: Linha 58
  ```bash
  timeout "$CMD_TIMEOUT" oc get co network -o yaml 2>&1 | tee -a "$LOG_FILE"
  ```

- `simples.py`: Linha 40
  ```python
  ("=== NETWORK OPERATOR ===", ["oc", "get", "co", "network", "-o", "yaml"]),
  ```

- `simples.sh`: Linha 37
  ```bash
  timeout "$CMD_TIMEOUT" oc get co network -o yaml || echo "AVISO: comando retornou código $? ou excedeu timeout"
  ```

**Conclusão:** ✔ **Presente em todos os 4 scripts**

Intencional. Informação crítica sobre rede e relativamente rápida de coletar.

---

### 7. Disco do Elasticsearch (`oc project openshift-logging` + `df` nos pods)

**Implementação:**
- `completo.py`: **NÃO existe** — função `main()` não inclui nenhuma lógica para Elasticsearch

- `completo.sh`: Linha 61-67
  ```bash
  echo -e "\n=== 8. Coletando informações do Uso de disco (Elasticsearch) ===" | tee -a "$LOG_FILE"
  oc project openshift-logging 2>&1 | tee -a "$LOG_FILE"
  
  for pod in $(oc get pods -l component=elasticsearch -o name 2>/dev/null); do
      echo "### $pod ###" | tee -a "$LOG_FILE"
      timeout "$CMD_TIMEOUT" oc -c elasticsearch exec "$pod" -- df -kh 2>&1 | grep persistent | tee -a "$LOG_FILE"
  done
  ```

- `simples.py`: Linha 41 (comando incompleto) e Linha 64-74
  ```python
  ("=== Coletando informações do Uso de disco ===", ["oc", "project", "openshift-logging"]),
  ```
  Executa `oc project openshift-logging` (linha 41), depois coleta disco dos pods:
  ```python
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
  ```

- `simples.sh`: **NÃO existe** — bloco redirigido (linhas 24-38) termina sem coletar disco. A linha 40 só imprime o arquivo de log.

**Conclusão:** ✖ Divergência real

| Script | Coleta disco? | Detalhes |
|--------|:-------------:|----------|
| `completo.py` | **NÃO** | Não há código para este passo |
| `completo.sh` | **SIM** | Completo: `oc project` + loop `df` nos pods |
| `simples.py` | **SIM** | Incompleto: só executa `oc project openshift-logging` na linha 41 (sem gravar saída); depois coleta disco manualmente |
| `simples.sh` | **NÃO** | Não há código para este passo |

**Razão:** Possível bug ou descuido na implementação:
- `simples.py` começou a incluir a coleta de disco (provavelmente copiada de `completo.sh`), mas fez incompleto:
  - Executa `oc project openshift-logging` como comando (linha 41) sem gravar a saída dele mesmo
  - Depois coleta os pods Elasticsearch fora da lista principal (linhas 64-74)
- `completo.py` não inclui disco (pode ser intencional se Elasticsearch não é crítico para "diagnóstico completo de cluster")
- `simples.sh` não inclui disco (intencional: "simples" = menos informação)

---

## Resumo das conclusões

| Divergência | Intencional? | Tipo | Recomendação |
|-------------|:----------:|------|--------------|
| Must-gather padrão ausente em `simples.*` | ✔ **SIM** | Design | Manter (versão simples = diagnóstico rápido) |
| Logs do etcd ausentes em `simples.*` | ✔ **SIM** | Design | Manter (informação pesada, só em diagnóstico completo) |
| Disco do Elasticsearch inconsistente | ❓ **PARCIAL** | Bug/Descuido | Revisar: `simples.py` implementa disco de forma incompleta; `completo.py` deveria incluir disco |
| `PIPESTATUS` em `completo.sh` sempre mostra código 1 | ✔ **SIM** | Pegadinha | Documentado em CLAUDE.md; considerar correção futura |
| Timeout em `completo.py` só verificado com saída | ✔ **SIM** | Design | Documentado; considerar melhoria futura |

