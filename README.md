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

## ============================

## 1️⃣ coleta_ocp_completo.py

## ============================

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

- **Execução de comandos com registro estruturado** na função `run_command()`
- **Captura automática do nome do pod etcd** usando `oc get pods -n openshift-etcd -o name`
- **Tratamento de exceções** para timeout e falhas de execução
- **Saída em tempo real** dos comandos
- **Resumo final** com localização dos arquivos gerados

---

## ============================

## 2️⃣ coleta_ocp_completo.sh

## ============================

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

- **Função `executar_comando`** para registro formatado
- **Identificação automática do pod etcd**
- **Verificação de existência do KUBECONFIG**
- **Saída em tempo real** para terminal e arquivo
- **Tratamento básico de erros**

---

## ============================

## 3️⃣ coleta_ocp_simples.sh

## ============================

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

- **Execução mínima** de comandos essenciais
- **Redirecionamento simples** de saída
- **Must-gather incluído** no fluxo principal
- **Uso de nome fixo** para o pod etcd: `etcd-master-0.ocp.embasanet.ba.gov.br`
- **Sem verificações complexas** para máxima velocidade

---

## ============================

## 4️⃣ coleta_ocp_simples.py

## ============================

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
| Must-gather com timeout           | ✔️          | ✔️          | ✖️         | ✖️         |
| Logs detalhados e organizados     | ✔️          | ✔️          | Médio      | Básico     |
| Descoberta automática do pod etcd | ✔️          | ✔️          | ✖️         | ✖️         |
| Tratamento de exceções            | ✔️          | Básico      | Básico     | Básico     |
| Saída em tempo real               | ✔️          | ✔️          | ✖️         | ✖️         |
| Verificação de KUBECONFIG         | ✔️          | ✔️          | ✖️         | ✖️         |
| Velocidade                        | Médio       | Médio       | Rápido     | Rápido     |
| Flexibilidade                     | Alta        | Média       | Baixa      | Baixa      |

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
Mais rápido, menos detalhado, ideal para verificação rápida do estado do cluster.

### 🎯 Preferência por Python com simplicidade

→ **Use:** `coleta_ocp_simples.py`  
Quando se deseja a simplicidade do Bash mas com a estrutura do Python.

---

## 📝 Notas Importantes

1. **Permissões:** Todos os scripts devem ser executados com permissões elevadas
2. **Storage:** Verifique espaço em disco suficiente para os arquivos do must-gather
3. **Rede:** Certifique-se de ter acesso aos registros container necessários
4. **Tempo:** O must-gather pode levar vários minutos dependendo do tamanho do cluster
5. **Backup:** Os scripts não fazem backup de dados - são apenas para coleta de informações

---

## 🔄 Atualizações

- **2024**: Adicionadas versões Python com melhor tratamento de erros
- **Scripts otimizados** para OpenShift 4.x
- **Suporte** para must-gather de CNV (Container Native Virtualization)
