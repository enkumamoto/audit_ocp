# SKILLS.md

Skills específicas deste repositório para o Claude Code.

## Convenção

Cada skill vive em `.claude/skills/<nome>/SKILL.md`. Toda skill nova deve ser listada na tabela abaixo com nome, gatilho de uso e resumo.

| Skill | Quando usar | Resumo |
| --- | --- | --- |
| `coleta-ocp` | Ao rodar diagnóstico/auditoria em um cluster OpenShift usando os scripts deste repo | Escolhe e executa o script de coleta (completo vs. simples, Python vs. Bash) conforme a urgência e o ambiente disponível |

## coleta-ocp

**Gatilho:** pedidos como "colete informações do cluster", "rode o diagnóstico do OCP", "faça um must-gather", "investigue o etcd".

**Lógica de escolha:**
- Diagnóstico completo / auditoria → `coleta_ocp_completo.py` (preferencial) ou `coleta_ocp_completo.sh` (se Python indisponível no nó)
- Investigação rápida / emergência → `coleta_ocp_simples.py` ou `coleta_ocp_simples.sh`

**Pré-requisitos a verificar antes de rodar:**
- Binário `oc` no PATH
- Acesso ao KUBECONFIG local: `/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig`
- Permissões de root (ou equivalentes) e espaço em disco para o must-gather
- Nos scripts `simples.*`, o nome do pod etcd é fixo (`etcd-master-0.ocp.embasanet.ba.gov.br`) — confirmar que corresponde ao ambiente alvo antes de executar

**Saída:** arquivo `ocp_debug_YYYYMMDD_HHMMSS.txt` (completo) ou `ocp_quick_YYYYMMDD_HHMMSS.txt` (simples), além de diretórios do must-gather quando aplicável. Esses artefatos não devem ser commitados (ver `.gitignore`).
