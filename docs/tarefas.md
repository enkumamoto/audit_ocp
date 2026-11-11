# Tarefas: Refatoração e Sincronização — audit_ocp

## 📊 Resumo executivo

**Problema:** 4 scripts (Python + Bash, versões completo/simples) com código duplicado, passos inconsistentes e README desatualizado.

**Solução:** Sincronizar scripts em 7 tarefas (Branch 1: `feat/audit-sync-scripts`), depois opcionalmente refatorar com lib compartilhada (Branch 2: `feat/audit-lib-refactor`).

**Abordagem:** Começar com Opção A (sincronizar independentes, baixo risco); depois avaliar Opção B (lib compartilhada).

---

## 🎯 Branch 1: feat/audit-sync-scripts

### T1: Validar e documentar divergências reais

- **Descrição:** Analisar cada um dos 4 scripts e confirmar a tabela de divergências documentada em CLAUDE.md
- **Critério de aceite:** 
  - Arquivo `docs/divergencias.md` criado com tabela confirmada
  - Cada diferença explicada (intencional ou bug?)
- **Depende de:** —
- **Arquivos:** `README.md`, `CLAUDE.md`, `coleta_ocp_completo.py`, `coleta_ocp_completo.sh`, `coleta_ocp_simples.py`, `coleta_ocp_simples.sh`
- **Reaproveita:** Análise inicial de Shikamaru

### T2: Decidir comportamento canônico

- **Descrição:** Documentar qual versão serve como referência; quais passos são obrigatórios vs. opcionais
- **Critério de aceite:**
  - Documento `docs/decisoes.md` com decisões arquiteturais
  - Decisão: `completo.*` coleta tudo (must-gather padrão + CNV + logs etcd + network); `simples.*` coleta mínimo (must-gather CNV + status ops + pods etcd + network)
- **Depende de:** T1
- **Arquivos:** `docs/divergencias.md`, `CLAUDE.md`

### T3: Sincronizar completo.py e completo.sh

- **Descrição:** Garantir que as duas versões têm os mesmos passos de coleta, na mesma ordem
- **Critério de aceite:**
  - `completo.py` e `completo.sh` têm sequência idêntica de comandos
  - Testes de sintaxe: `python3 -m py_compile coleta_ocp_completo.py` ✅ e `bash -n coleta_ocp_completo.sh` ✅
  - Disco Elasticsearch removido de `completo.sh` (inconsistente com .py)
  - Must-gather padrão incluído em ambas
  - Logs do etcd incluídos em ambas
- **Depende de:** T2
- **Arquivos:** `coleta_ocp_completo.py`, `coleta_ocp_completo.sh`

### T4: Sincronizar simples.py e simples.sh

- **Descrição:** Garantir que as duas versões simples têm passos idênticos
- **Critério de aceite:**
  - `simples.py` e `simples.sh` têm sequência idêntica de comandos
  - Testes de sintaxe passam
  - Ambas SEM must-gather padrão (apenas CNV)
  - Ambas SEM logs do etcd
  - Decisão: disco Elasticsearch em ambas ou em nenhuma (conforme T2)
- **Depende de:** T2
- **Arquivos:** `coleta_ocp_simples.py`, `coleta_ocp_simples.sh`

### T5: Corrigir bugs técnicos

- **Descrição:** Resolver pegadinhas técnicas identificadas no CLAUDE.md
- **Critério de aceite:** Todos os 4 pontos abaixo corrigidos:
  - **T5a (completo.py):** Timeout funciona mesmo com comando silencioso (usar `select()` em vez de polling por linha)
  - **T5b (completo.sh):** `PIPESTATUS[0]` mostra código real do comando (não do `[...]`)
  - **T5c (completo.sh):** `oc project openshift-logging` não deixa contexto permanentemente alterado
  - **T5d (simples.py):** `sys.exit(130)` no handler de Ctrl+C (como simples.sh já faz)
- **Depende de:** T3, T4
- **Arquivos:** `coleta_ocp_completo.py`, `coleta_ocp_completo.sh`, `coleta_ocp_simples.py`, `coleta_ocp_simples.sh`

### T6: Atualizar README.md

- **Descrição:** Sincronizar documentação com comportamento real dos scripts
- **Critério de aceite:**
  - Removidas menções a função `executar_comando` (inexistente)
  - Tabela de comparação atualizada com reais capacidades
  - Coluna de timeout corrigida
  - Comportamento dos scripts `simples.*` explicado corretamente (não coletam logs etcd)
  - Seção "Pegadinhas" movida do CLAUDE.md para README (ou referenciada)
- **Depende de:** T1-T5
- **Arquivos:** `README.md`

### T7: Testes de integridade

- **Descrição:** Criar testes que validam consistência entre os 4 scripts
- **Critério de aceite:**
  - Script `tests/test_scripts_consistency.sh` criado
  - Valida que `completo.*` têm N passos de coleta; `simples.*` têm M passos
  - Nenhuma diferença acidental entre .py e .sh (mesma ordem de comandos)
  - Testes rodam localmente e em CI
- **Depende de:** T1, T2
- **Arquivos:** `tests/test_scripts_consistency.sh`

---

## 🔧 Branch 2: feat/audit-lib-refactor (Opcional, para depois)

### T8: Refatorar com lib compartilhada

- **Descrição:** Criar `lib_coleta.py` e `lib_coleta.sh` com funções comuns; reescrever 4 scripts como wrappers
- **Critério de aceite:**
  - `lib_coleta.py` exporta: `run_command()`, `setup_kubeconfig()`, `get_etcd_pod()`
  - `lib_coleta.sh` exporta: `executar_comando()`, `verificar_kubeconfig()`, `descobrir_pod_etcd()`
  - 4 scripts reescritos; ~80% menos duplicação
  - Comportamento idêntico ao de T1-T7
  - Testes passam
- **Depende de:** T1-T7 (Branch 1 deve estar pronto e aprovado)
- **Arquivos:** `lib_coleta.py`, `lib_coleta.sh`, `coleta_ocp_completo.py`, `coleta_ocp_completo.sh`, `coleta_ocp_simples.py`, `coleta_ocp_simples.sh`

---

## 📋 Checklist de progresso

### Branch 1: feat/audit-sync-scripts

- [x] T1: Validar e documentar divergências reais
- [x] T2: Decidir comportamento canônico
- [x] T3: Sincronizar completo.py e completo.sh
- [x] T4: Sincronizar simples.py e simples.sh
- [x] T5: Corrigir bugs técnicos
- [x] T6: Atualizar README.md
- [ ] T7: Testes de integridade

### Branch 2: feat/audit-lib-refactor (opcional)

- [ ] T8: Refatorar com lib compartilhada

---

## 🎬 Próximos passos

1. ⏸ **Aprovação do usuário:** Confirmar escopo, ordem das tarefas, decisões em T2
2. Papel 2 (Naruto) implementa T1-T7 na branch `feat/audit-sync-scripts`
3. Papel 3 (Kakashi) cria testes para cada tarefa
4. Papel 4 (Neji) revisa o código
5. Papel 5 (Hashirama) configura CI (linting de Python/Bash, testes de sintaxe)
6. Papel 6 (Shino) monitora execução do pipeline
7. Papel 7 (Sai) documenta decisões técnicas em `docs/adr/`

**Recomendação:** Começar com **Branch 1 (T1-T7)** de baixo risco; depois avaliar **Branch 2 (T8)** se a sincronização passar na revisão.

---

**Status:** ⏸ Aguardando aprovação do usuário
