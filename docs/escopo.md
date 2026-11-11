# Escopo: Refatoração e Sincronização — audit_ocp

## Visão geral

Refatorar os 4 scripts de coleta de informações do OpenShift (Python e Bash, versões completa e simples) para eliminar duplicação de código e sincronizar o README com o comportamento real dos scripts, corrigindo inconsistências documentadas em CLAUDE.md.

## Requisitos funcionais

1. Unificar lógica compartilhada entre `completo.py`, `completo.sh`, `simples.py` e `simples.sh`
2. Eliminar duplicação de passos de coleta que diferem entre as versões
3. Tornar o comportamento dos 4 scripts consistente ou documentar divergências deliberadas
4. Sincronizar README com a realidade: corrigir funções inexistentes, passos incorretos, timeouts, verificações de KUBECONFIG

## Requisitos não-funcionais

- Manter compatibilidade com OpenShift 4.x e nós master
- Sem dependências além de `oc` e biblioteca padrão do Python
- Scripts devem falhar graciosamente (registrar erro, não interromper fluxo)
- Ctrl+C deve encerrar com código 130

## Decisões de arquitetura (a confirmar)

1. **Compartilhamento de código:** Criar funções/módulos reutilizáveis?
   - Opção A: Arquivo `lib_coleta.py` + `lib_coleta.sh` com funções comuns
   - Opção B: Manter 4 scripts independentes, mas com lógica idêntica (mais simples)
   
2. **Sincronização de mudanças:** Quando um passo for atualizado, como garantir que todos os 4 scripts sejam atualizados?
   - Opção A: Testes de integridade que verificam se os 4 scripts têm os mesmos passos
   - Opção B: Script gerador que cria as 4 variantes a partir de uma fonte única

## Stack

- **Linguagens:** Python 3, Bash
- **Ferramentas:** `oc` (Kubernetes CLI), `timeout` (Bash)
- **Ambiente:** Nó master do OpenShift 4.x
- **Validação local:** `python3 -m py_compile`, `bash -n`

## Plataforma e deploy

- Sem deploy automático — scripts são cópias manuais para nós master
- Documentação: README atualizado, comentários nos scripts, CLAUDE.md refletindo realidade

## Status

- ⏳ Aguardando aprovação do Papel 1 (Planejador) em habblaud
