# Decisões Arquiteturais: Comportamento Canônico dos Scripts

**Data:** 2026-11-11  
**Contexto:** Sincronização de 4 scripts de coleta (completo.py/sh, simples.py/sh)  
**Decisores:** Papel 2 (Naruto Uzumaki)

---

## 1. Objetivo das duas versões

### Versão `completo.*`: Diagnóstico Completo do Cluster

**Objetivo:** Coletar tudo o que for relevante para diagnóstico profundo, troubleshooting aprofundado e auditoria de incidentes.

**Inclui:**
- ✅ Must-gather com imagem CNV (`--image=...cnv-must-gather-rhel9:v4.16.21`)
- ✅ Must-gather padrão (sem imagem customizada)
- ✅ Status dos operators (`oc get co`)
- ✅ Pods do etcd (`oc get pods -n openshift-etcd`)
- ✅ Logs do etcd (`oc -n openshift-etcd logs <pod>`)
- ✅ Operador de rede em YAML (`oc get co network -o yaml`)
- ✅ **Disco do Elasticsearch** (`oc project openshift-logging` + `df` nos pods)

**Tempo de execução:** 10-20 minutos (worst-case com timeouts)  
**Storage necessário:** ~2-5 GB (must-gather padrão é pesado)

**Justificativa:** A versão completa sacrifica tempo e storage para capturar o máximo de contexto. Inclui logs volumosos (etcd) e coletores pesados (must-gather padrão) que não são essenciais para diagnóstico rápido, mas são críticos para root-cause analysis profundo.

---

### Versão `simples.*`: Diagnóstico Rápido e Essencial

**Objetivo:** Coletar o mínimo necessário para diagnóstico rápido, snapshot de estado crítico do cluster sem overhead.

**Inclui:**
- ✅ Must-gather com imagem CNV (leve)
- ✖ Must-gather padrão (REMOVIDO — muito pesado)
- ✅ Status dos operators
- ✅ Pods do etcd
- ✖ Logs do etcd (REMOVIDO — muito voluminoso)
- ✅ Operador de rede em YAML
- ✖ **Disco do Elasticsearch** (REMOVIDO — métrica auxiliar, não essencial)

**Tempo de execução:** 2-5 minutos  
**Storage necessário:** ~200-500 MB

**Justificativa:** A versão simples prioriza velocidade e leveza. Remove passos que são informativos mas não críticos:
- Must-gather padrão: duplicaria informação já capturada pelo must-gather CNV
- Logs do etcd: podem ocupar centenas de MB e não são necessários para snapshot rápido
- Disco do Elasticsearch: informação auxiliar, útil em diagnóstico completo mas não essencial para determinação rápida de estado do cluster

---

## 2. Decisão sobre Disco do Elasticsearch

### Status atual (documentado em `docs/divergencias.md`)

| Script | Coleta disco? | Detalhes |
|--------|:-------------:|----------|
| `completo.py` | **NÃO** | Falta código |
| `completo.sh` | **SIM** | Completo |
| `simples.py` | **SIM** | Incompleto (bug) |
| `simples.sh` | **NÃO** | Intencional |

### Decisão

**Disco do Elasticsearch será incluído SIM em `completo.*` e NÃO em `simples.*`**

### Justificativa

1. **Para `completo.*`: SIM**
   - Elasticsearch é componente crítico de logging e observabilidade
   - Disco cheio é causa comum de problemas de logs não sendo ingeridos
   - Faz parte de "diagnóstico completo" colher espaço disponível em pods críticos
   - Impacto de tempo: ~30-60s adicionais (aceitável em contexto de 10-20 minutos)

2. **Para `simples.*`: NÃO**
   - Espaço em disco é métrica auxiliar, não essencial para snapshot rápido
   - Seu.goal é responder "qual é o estado atual do cluster?", não "como estão os recursos?"
   - Reduz tempo de execução e storage consumido
   - Se houver necessidade de espaço em disco, usuário roda `completo.*`

### Implementação

- **T3:** `completo.py` será atualizado para incluir disco do Elasticsearch (copiar lógica de `completo.sh`, mas via Python)
- **T3:** `completo.sh` manterá disco conforme está
- **T4:** `simples.py` terá código de disco removido (bug será corrigido removendo a funcionalidade)
- **T4:** `simples.sh` permanecerá sem disco (conforme design)

---

## 3. Versão Canônica: `completo.py`

### Decisão

**`completo.py` é a versão canônica (referência de verdade).**

### Justificativa

1. **Linguagem escolhida:** Python é mais estruturado que Bash para lógica complexa
   - Timeout com `select()` é mais robusto que em Bash
   - Descoberta de pod etcd é mais legível com variáveis Python
   - Tratamento de erro e logging são mais claros

2. **Estrutura de código:**
   - Lista de comandos `commands` é declarativa e fácil de sincronizar
   - Função `run_command()` centraliza execução e tratamento de timeout
   - Handler de Ctrl+C é mais previsível

3. **Sincronização futura:**
   - Mudanças em passos de coleta começam em `completo.py`
   - Mudanças em versão de must-gather (`cnv-must-gather-rhel9:vX.Y.Z`) começam em `completo.py`
   - `completo.sh` é reescrito a partir da lista em `completo.py`
   - `simples.*` herda a lista de `completo.*`, removendo passos opcionais

4. **Reaproveitamento em T8 (lib refactor):**
   - `completo.py` serve como base para `lib_coleta.py`
   - Facilita futura migração para uma lib compartilhada

### Implementação

- **T2 (este documento):** Registra que `completo.py` é canônica
- **T3:** Quando sincronizar, usar estrutura de `completo.py` como referência
- **T4:** Idem para `simples.py`
- **T5:** Bugs em `completo.py` são prioridade (cascata para `.sh`)

---

## 4. Sequência de Passos Comum

### Em `completo.py` e `completo.sh`

Ordem de execução (idêntica em ambas):

1. Validar `oc` e KUBECONFIG
2. Executar must-gather CNV (leve, rápido)
3. Executar must-gather padrão (pesado, comprehensive)
4. Coletar status dos operators
5. Coletar pods do etcd
6. Coletar logs do etcd (com fallback)
7. Coletar operador de rede em YAML
8. Coletar disco do Elasticsearch (novo em `completo.py`)

### Em `simples.py` e `simples.sh`

Ordem de execução (idêntica em ambas, subset de completo):

1. Validar `oc` e KUBECONFIG
2. Executar must-gather CNV (leve)
3. Coletar status dos operators
4. Coletar pods do etcd
5. Coletar operador de rede em YAML

(Sem must-gather padrão, sem logs etcd, sem disco Elasticsearch)

---

## 5. Implicações para Tarefas Futuras

### T3: Sincronizar `completo.py` e `completo.sh`

- Usar sequência de `completo.py` como referência
- Adicionar disco do Elasticsearch a `completo.py`
- Remover disco de `completo.sh` (será readicionado quando `completo.py` tiver)

### T4: Sincronizar `simples.py` e `simples.sh`

- Remover disco de `simples.py` (bug será corrigido removendo funcionalidade)
- Remover must-gather padrão (já ausente em `simples.sh`)
- Remover logs etcd (já ausentes em `simples.sh`)

### T5: Bugs técnicos

- Corrigir timeout em `completo.py` (usar `select()`)
- Corrigir PIPESTATUS em `completo.sh` (ler antes do `[...]`)
- Corrigir contexto permanentemente alterado em `completo.sh`
- Adicionar Ctrl+C handler a `simples.py`

### T6: README.md

- Tabela de comparação refletirá sequências de T3 e T4
- Remover descrições incorretas sobre logs etcd em `simples.*`
- Documentar que disco Elasticsearch é coleta pesada (apenas em `completo.*`)

---

## Referências

- `docs/divergencias.md` — análise detalhada das divergências reais
- `docs/tarefas.md` — cronograma de sincronização
- `CLAUDE.md` — pegadinhas técnicas e convenções do projeto
