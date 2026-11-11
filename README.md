# Scripts de Coleta de Informações do OpenShift (OCP)

Este repositório contém scripts para coleta de logs, status e informações essenciais de um cluster **OpenShift**. Eles são úteis para troubleshooting, análise de incidentes e extração rápida de dados críticos como:

- Operators (`oc get co`)
- Estado dos pods do `openshift-etcd`
- Logs do etcd
- Execução do _must-gather_
- Output consolidado em arquivos de log versionados por timestamp

---

## 📌 Conteúdo dos Arquivos

| Arquivo                    | Linguagem | Complexidade | Finalidade                                                                  |
| -------------------------- | --------- | ------------ | --------------------------------------------------------------------------- |
| **coleta_ocp_completo.py** | Python    | Alta         | Script mais robusto, com timeout, tratamento de exceções e coleta completa. |
| **coleta_ocp_completo.sh** | Bash      | Média        | Versão shell equivalente ao script Python, com logs detalhados.             |
| **coleta_ocp_simples.sh**  | Bash      | Baixa        | Coleta mais rápida e resumida, ideal para diagnósticos rápidos.             |
| **coleta_ocp_simples.py**  | Python    | Baixa        | Versão Python simplificada para coleta rápida.                              |

---

## 📂 Pré-requisitos

- Acesso ao nó com permissões para leitura do Kubernetes local
- Binário `oc` instalado e disponível no PATH
- Acesso ao arquivo:
  ```
  /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
  ```
- Python 3 (somente para os scripts `.py`)
- Execução como root ou com permissões equivalentes

---

## 🧭 Caminho do KUBECONFIG

Todos os scripts utilizam:

```
/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
```

Este arquivo é usado quando a API Server está inacessível, mas o nó master possui kubeconfigs locais para gerenciamento interno.

---

## 1️⃣ coleta_ocp_completo.py

**📄 Arquivo:** `coleta_ocp_completo.py`  
**Linguagem:** **Python 3**

Este é o script **mais completo** do repositório. Possui:

- Função genérica para executar comandos com timeout
- Captura de saída e stderr
- Gerenciamento automático de logs
- Execução do _must-gather_ com timeout
- Coleta inteligente dos logs do etcd (descobre o pod automaticamente)

### ▶️ Execução

```bash
chmod +x coleta_ocp_completo.py
./coleta_ocp_completo.py
```

O script gerará:

- Um arquivo: `ocp_debug_YYYYMMDD_HHMMSS.txt`
- Diretórios do must-gather com timestamp

### 🔍 Principais funcionalidades

- **Execução de comandos com timeout robusto** via `run_command()` que usa `select()` para detectar timeout mesmo em comandos silenciosos
- **Captura automática do nome do pod etcd** usando `oc get pods -n openshift-etcd -o name`
- **Tratamento robusto de exceções** para timeout e falhas de execução
- **Saída em tempo real** dos comandos
- **Resumo final** com localização dos arquivos gerados
- **Coleta de disco do Elasticsearch** para diagnóstico completo de espaço disponível

---

## 2️⃣ coleta_ocp_completo.sh

**📄 Arquivo:** `coleta_ocp_completo.sh`  
**Linguagem:** **Bash**

Versão shell do script Python, também coletando todas as informações essenciais. Inclui:

- Execução do must-gather
- Coleta completa dos logs etcd
- Identificação automática do pod
- Logs estruturados em um único arquivo

### ▶️ Execução

```bash
chmod +x coleta_ocp_completo.sh
./coleta_ocp_completo.sh
```

Criará: `ocp_debug_YYYYMMDD_HHMMSS.txt`

### 🔍 Principais funcionalidades

- **Funções estruturadas** para execução com timeout via `timeout` command
- **Identificação automática do pod etcd** com fallback para `etcd-master-0.<domínio>`
- **Verificação de existência do KUBECONFIG**
- **Saída em tempo real** para terminal e arquivo
- **Tratamento de erros** via `PIPESTATUS`
- **Coleta de disco do Elasticsearch** para diagnóstico completo

---

## 3️⃣ coleta_ocp_simples.sh

**📄 Arquivo:** `coleta_ocp_simples.sh`  
**Linguagem:** **Bash**

Este é o script mais enxuto e rápido. Indicado quando você precisa apenas:

- Ver estado dos operators
- Listar pods do etcd
- Ver logs do etcd
- Rodar must-gather

### ▶️ Execução

```bash
chmod +x coleta_ocp_simples.sh
./coleta_ocp_simples.sh
```

Gera: `ocp_quick_YYYYMMDD_HHMMSS.txt`

### 🔍 Funcionalidades principais

- **Execução mínima** de comandos essenciais (status ops, pods, network)
- **Redirecionamento simples** de saída
- **Must-gather CNV incluído** no fluxo principal (leve e rápido)
- **SEM coleta de:** must-gather padrão, logs do etcd, disco do Elasticsearch
- **Verificação de KUBECONFIG** e timeout aplicados
- **Máxima velocidade:** ~2-5 minutos

---

## 4️⃣ coleta_ocp_simples.py

**📄 Arquivo:** `coleta_ocp_simples.py`  
**Linguagem:** **Python 3**

Versão Python simplificada para coleta rápida. Características:

- Execução sequencial de comandos
- Captura de saída pós-execução
- Estrutura mínima e eficiente

### ▶️ Execução

```bash
chmod +x coleta_ocp_simples.py
./coleta_ocp_simples.py
```

Gera: `ocp_quick_YYYYMMDD_HHMMSS.txt`

### 🔍 Funcionalidades principais

- **Execução rápida** sem overhead complexo
- **Captura eficiente** de stdout/stderr
- **Tratamento básico** de exceções
- **Saída consolidada** em arquivo único

---

## 📊 Comparação entre os scripts

| Recurso                           | completo.py | completo.sh | simples.sh | simples.py |
| --------------------------------- | ----------- | ----------- | ---------- | ---------- |
| Must-gather com timeout           | ✔️ (select) | ✔️ (timeout)| ✖️         | ✖️         |
| Must-gather padrão + CNV          | ✔️          | ✔️          | ✖️         | ✖️         |
| Logs do etcd                      | ✔️          | ✔️          | ✖️         | ✖️         |
| Disco do Elasticsearch            | ✔️          | ✔️          | ✖️         | ✖️         |
| Status dos operadores             | ✔️          | ✔️          | ✔️         | ✔️         |
| Pods do etcd                      | ✔️          | ✔️          | ✔️         | ✔️         |
| Operador de rede (YAML)           | ✔️          | ✔️          | ✔️         | ✔️         |
| Descoberta automática do pod etcd | ✔️          | ✔️          | ✖️         | ✖️         |
| Verificação de KUBECONFIG         | ✔️          | ✔️          | ✔️         | ✔️         |
| Tratamento de exceções            | ✔️ (Alto)   | Médio       | Básico     | Básico     |
| Saída em tempo real               | ✔️          | ✔️          | ✖️         | ✖️         |
| Velocidade                        | 10-20 min   | 10-20 min   | 2-5 min    | 2-5 min    |
| Storage necessário                | ~2-5 GB     | ~2-5 GB     | ~200-500MB | ~200-500MB |

---

## 🚀 Como escolher qual script usar?

### 🎯 Diagnóstico completo do cluster

→ **Use:** `coleta_ocp_completo.py`  
Ideal para auditorias, troubleshooting detalhado e coleta abrangente com máxima confiabilidade.

### 🎯 Execução robusta em ambientes sem Python

→ **Use:** `coleta_ocp_completo.sh`  
Equivalente ao Python em funcionalidades, porém em Bash puro.

### 🎯 Investigação rápida / emergência

→ **Use:** `coleta_ocp_simples.sh` ou `coleta_ocp_simples.py`  
Mais rápido (2-5 minutos), menos detalhado, ideal para verificação rápida do estado do cluster. **Não coleta** must-gather padrão, logs do etcd ou disco do Elasticsearch.

### 🎯 Preferência por Python com simplicidade

→ **Use:** `coleta_ocp_simples.py`  
Quando se deseja a simplicidade do Bash mas com a estrutura do Python. Mesma funcionalidade reduzida de `coleta_ocp_simples.sh`.

---

## 📝 Notas Importantes

1. **Permissões:** Todos os scripts devem ser executados com permissões elevadas (root ou equivalente)
2. **Storage:** Verifique espaço em disco suficiente
   - **Versão completa** (`completo.*`): ~2-5 GB (must-gather padrão é pesado)
   - **Versão simples** (`simples.*`): ~200-500 MB
3. **Rede:** Certifique-se de ter acesso aos registros container necessários
4. **Tempo:** O must-gather pode levar vários minutos dependendo do tamanho do cluster
5. **Backup:** Os scripts não fazem backup de dados - são apenas para coleta de informações

---

## ⚠️ Pegadinhas e Limitações

- **Timeout em `completo.py`:** Agora corrigido com `select()` para monitorar saída, funciona mesmo com comandos silenciosos que não geram linhas de output
- **`PIPESTATUS` em `completo.sh`:** Corrigido; captura status do comando imediatamente após pipe, antes de qualquer outro comando
- **`oc project openshift-logging` em coleta de Elasticsearch:** Altera o contexto do KUBECONFIG local do nó; é restaurado automaticamente após a coleta
- **Código de saída 130 em `simples.py`:** Agora retorna código correto quando Ctrl+C é pressionado (equivalente ao Bash)
- **Descoberta de pod etcd:** Os scripts `completo.*` descobrem o pod automaticamente; scripts `simples.*` não coletam logs do etcd

---

## 🔄 Atualizações

- **2024**: Adicionadas versões Python com melhor tratamento de erros
- **Scripts otimizados** para OpenShift 4.x
- **Suporte** para must-gather de CNV (Container Native Virtualization)
