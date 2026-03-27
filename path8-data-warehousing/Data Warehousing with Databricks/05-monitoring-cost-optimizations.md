# Databricks — Monitoring: Cost Optimization
 O destaque deste módulo é mesmo a árvore de decisão de sizing — é o tipo de coisa que pode aparecer em entrevistas ou certificações. 
 A lógica é simples: o Query Profiler diz-te o quê está mal, o monitoring tab diz-te quando acontece, e com isso decides se aumentas o tamanho, adicionas clusters, ou reduces para poupar custos. 

## 1. Best Practices (visão geral)

| Prática | Descrição |
|---|---|
| **Serverless SQL Warehouses** | Scaling rápido, terminação idle eficiente, startup rápido — reduz custos vs. setups não-serverless, especialmente para workloads BI com picos |
| **Dimensionar corretamente** | Ajustar o tamanho do warehouse ao use case previsto |
| **Autoscaling** | Ajuste dinâmico de recursos de compute para workloads variáveis — minimiza desperdício em idle |
| **Managed Tables** | Dados em estrutura de alto desempenho com otimizações automáticas do Databricks |
| **Otimizar SQL** | Usar predicate pushdown, partition pruning, column pruning; reduzir leituras e processamento desnecessários |
| **Query Profiling** | Usar o Query Profiler para identificar e corrigir bottlenecks |

---

## 2. Query Profiling

O **Query Profiler** é uma representação gráfica do timing de execução de uma query.

### Para que serve

- Visualizar cada operador da query e métricas associadas (tempo, rows processados, memória)
- Identificar rapidamente a parte mais lenta de uma execução
- Avaliar o impacto de modificações à query
- Descobrir e corrigir erros comuns: **exploding joins**, **full table scans**

### O que mostra

- **Time spent** por operação
- **Number of rows** processados
- **Memory consumption**
- **Bytes spilled to disk** (sinal de que o warehouse é demasiado pequeno)

> Podes usar o **query history** para ver perfis de execuções anteriores — não só das queries em curso.

---

## 3. SQL Warehouse Monitoring Tab

A aba de monitoring do SQL Warehouse dá uma visão holística de como os workloads estão a usar o compute.

| Componente | O que mostra |
|---|---|
| **Live statistics** | Status do warehouse, queries em execução, queries em fila, cluster count atual |
| **Time scale filtering** | Ajusta o intervalo de tempo para os gráficos e histórico |
| **Peak query count chart** | Nº máximo de queries concorrentes (running + queued) — cada ponto = pico num janela de 5 min |
| **Completed query count chart** | Nº de queries completadas (inclui canceladas e falhadas) no período |
| **Running clusters chart** | Nº de clusters alocados ao warehouse no período |
| **Query history table** | Todas as queries ativas no período: start time, duração, utilizador |

---

## 4. SQL Warehouse Sizing — Boas Práticas

### Abordagem recomendada pelo Databricks

> **Começa grande e vai descendo** — não o contrário.

1. Começa com um tamanho maior do que pensas precisar
2. Usa um **único SQL Warehouse serverless**
3. Deixa o Databricks fazer o **right-sizing** com autoscaling
4. Usa o **monitoring tab** e o **query profiler** para observar e ajustar

### Árvore de decisão para ajuste de tamanho

```
Queres diminuir latência?
├── Queries a fazer spill to disk? (Bytes spilled to disk > 1)
│   └── → Aumenta o tamanho do warehouse
├── Queries altamente paralelizáveis?
│   └── → Aumenta o tamanho do warehouse
└── Múltiplas queries em simultâneo?
    └── → Adiciona mais clusters (autoscaling)

Queres reduzir custos?
└── Desce o tamanho sem causar spill excessivo ou latência elevada
```

### Resumo visual

| Objetivo | Sintoma detetado | Ação |
|---|---|---|
| ↓ Latência | Spill to disk / queries paralelizáveis | Aumentar tamanho |
| ↓ Latência | Múltiplas queries simultâneas | Adicionar clusters |
| ↓ Custo | Warehouse sobredimensionado | Diminuir tamanho gradualmente |
