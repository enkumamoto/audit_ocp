# CLAUDE.md

Guia de contexto para o Claude Code trabalhar neste repositório.

## Uso de tokens

Repositório pequeno e de baixa complexidade. Em qualquer intervenção:
- Não leia arquivos inteiros sem necessidade; use grep/busca direcionada quando possível.
- Não gere resumos, relatórios ou documentos intermediários além do que foi pedido.
- Prefira edições pontuais (diff mínimo) a reescritas de arquivo.
- Evite explicações longas — respostas diretas e curtas.
- Não use subagentes para tarefas simples deste repo (poucos arquivos, contexto cabe direto).

## Sobre o repositório

Coleção de scripts (Python e Bash) para coleta de logs, status e diagnóstico de clusters **OpenShift (OCP)**, usados em troubleshooting, auditoria e análise de incidentes. Não é uma aplicação — são scripts standalone executados diretamente em um nó master do cluster.

## Arquivos principais

| Arquivo | Linguagem | Propósito |
| --- | --- | --- |
| `coleta_ocp_completo.py` | Python 3 | Coleta completa, com timeout, tratamento de exceções e descoberta automática do pod etcd. |
| `coleta_ocp_completo.sh` | Bash | Equivalente shell do script completo. |
| `coleta_ocp_simples.py` | Python 3 | Coleta rápida e mínima. |
| `coleta_ocp_simples.sh` | Bash | Coleta rápida e mínima em shell puro. |

Todos geram um arquivo de log local (`ocp_debug_*.txt` ou `ocp_quick_*.txt`) e usam o KUBECONFIG local:
```
/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
```

## Convenções ao editar

- Scripts devem continuar executáveis sem dependências externas além do binário `oc` e (para os `.py`) Python 3 padrão da lib.
- Mantenha o padrão de logging existente: cabeçalho com timestamp, saída em tempo real no terminal + arquivo, tratamento de erro sem interromper os demais comandos.
- Nomes de pods/hosts fixos (ex.: `etcd-master-0.ocp.embasanet.ba.gov.br`) em `coleta_ocp_simples.*` são específicos de um ambiente — não generalize sem confirmar com o usuário, já que outros scripts descobrem o pod dinamicamente via `oc get pods -n openshift-etcd -o name`.
- Não commitar arquivos de saída gerados pela execução dos scripts (`ocp_debug_*.txt`, `ocp_quick_*.txt`, diretórios de must-gather) — já ignorados no `.gitignore`.
- README.md está em português; mantenha esse idioma em documentação e mensagens de commit relacionadas, salvo indicação contrária.
