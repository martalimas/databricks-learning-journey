# SQL Constructs in Databricks — Temporary Views

**Módulo:** SQL Programming and Procedural Logic  
**Secção:** SQL Constructs in Databricks  
**Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner

---

## O que são Temporary Views?

Uma **Temporary View** é um resultado nomeado — essencialmente uma tabela virtual — que existe apenas durante a sessão ou job atual. Permite encapsular lógica de filtragem ou transformação complexa sob um único nome reutilizável, sem persistir dados em storage.

**Características principais:**
- Armazenada em memória (não em disco)
- Visível como uma tabela normal dentro do seu scope
- Útil para quebrar problemas em passos mais pequenos sem criar tabelas físicas
- Duas variantes: `TEMP VIEW` (local) e `GLOBAL TEMP VIEW` (partilhada)

---

## Anatomia de uma Temporary View

```sql
CREATE OR REPLACE TEMP VIEW late_shipments AS
SELECT
  l_orderkey,
  l_shipdate,
  l_commitdate
FROM samples.tpch.lineitem
WHERE l_shipdate > l_commitdate;
```

### As três partes:

| Parte | O que faz |
|---|---|
| `CREATE OR REPLACE TEMP VIEW nome` | Define a view — sobrepõe se já existir |
| `AS` + `SELECT ...` | Define a lógica da view (filtragem, transformação, joins, etc.) |
| `nome` em queries seguintes | Usa a view como se fosse uma tabela física |

Uma vez criada, qualquer query subsequente no mesmo notebook ou job pode referenciar `late_shipments` exactamente como referenciaria uma tabela real.

---

## GLOBAL TEMP VIEW

A `GLOBAL TEMP VIEW` é uma **Temporary View com scope alargado** — em vez de estar limitada ao notebook ou sessão atual, é visível a qualquer notebook ou job a correr no mesmo cluster do workspace.

```sql
CREATE OR REPLACE GLOBAL TEMP VIEW top_selling_products AS
SELECT
  l_partkey,
  SUM(l_quantity) AS total_quantity
FROM samples.tpch.lineitem
GROUP BY l_partkey
ORDER BY total_quantity DESC
LIMIT 10;
```

A Global Temp View fica guardada num schema especial chamado **`global_temp`**. Para a referenciar:

```sql
-- Tens de usar o prefixo global_temp
SELECT * FROM global_temp.top_selling_products;
```

---

## Comparação: TEMP VIEW vs GLOBAL TEMP VIEW

| | TEMP VIEW | GLOBAL TEMP VIEW |
|---|---|---|
| **Scope** | Notebook / sessão atual | Qualquer notebook no mesmo cluster |
| **Schema** | Implícito (sem prefixo) | `global_temp.nome_view` |
| **Duração** | Até o notebook/job terminar | Até o cluster ser reiniciado |
| **Caso de uso** | Lógica local a um único fluxo | Partilhar resultados entre notebooks ou utilizadores |

### Regra prática:
- Usa **`TEMP VIEW`** quando a lógica é local a um único notebook ou job e não precisas dos resultados fora dessa sessão
- Usa **`GLOBAL TEMP VIEW`** quando queres partilhar lógica entre diferentes notebooks, jobs ou utilizadores no mesmo cluster

---

## CTEs vs Temporary Views — quando usar cada um?

| | CTE | Temporary View |
|---|---|---|
| **Scope** | Uma única query | Toda a sessão / cluster |
| **Reutilização** | Dentro da mesma query | Em múltiplas queries diferentes |
| **Persistência** | Desaparece com a query | Persiste até a sessão terminar |
| **Melhor para** | Lógica intermédia dentro de uma query complexa | Staging de dados reutilizável entre queries |

> **Padrão comum:** usar uma CTE para construir lógica intermédia dentro de uma query, e uma Temp View para expor um resultado a queries subsequentes no mesmo notebook.

---

## Exercício prático (Community Edition)

```sql
-- Exercício 1: Criar uma Temp View de envios tardios
CREATE OR REPLACE TEMP VIEW late_shipments AS
SELECT
  l_orderkey,
  l_shipdate,
  l_commitdate,
  DATEDIFF(l_shipdate, l_commitdate) AS days_late
FROM samples.tpch.lineitem
WHERE l_shipdate > l_commitdate;

-- Reutilizar a view em queries separadas
SELECT COUNT(*) AS total_late FROM late_shipments;

SELECT * FROM late_shipments
ORDER BY days_late DESC
LIMIT 10;
```

```sql
-- Exercício 2: Global Temp View — top produtos por quantidade
CREATE OR REPLACE GLOBAL TEMP VIEW top_selling_products AS
SELECT
  l_partkey,
  SUM(l_quantity) AS total_quantity
FROM samples.tpch.lineitem
GROUP BY l_partkey
ORDER BY total_quantity DESC
LIMIT 10;

-- Para usar, tens SEMPRE de referenciar com o prefixo global_temp
SELECT * FROM global_temp.top_selling_products;
```

```sql
-- Exercício 3: Combinar Temp View com CTE
-- A view encapsula o staging; a CTE faz a análise em cima
WITH order_summary AS (
  SELECT
    l_orderkey,
    COUNT(*) AS late_items,
    AVG(days_late) AS avg_days_late
  FROM late_shipments        -- referencia a Temp View criada acima
  GROUP BY l_orderkey
)
SELECT *
FROM order_summary
WHERE late_items > 1
ORDER BY avg_days_late DESC;
```

---

## Key takeaways

- `TEMP VIEW` = tabela virtual em memória, scoped à sessão — ideal para staging de lógica reutilizável dentro de um notebook
- `GLOBAL TEMP VIEW` = mesmo conceito mas visível em todo o cluster — ideal para partilhar resultados entre notebooks ou utilizadores
- A diferença principal face a CTEs: a Temp View **sobrevive entre queries** na mesma sessão; a CTE desaparece no fim da query
- Sempre referenciar Global Temp Views com o prefixo `global_temp.`
