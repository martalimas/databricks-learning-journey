# SQL Constructs in Databricks — Parameterized SQL

**Módulo:** SQL Programming and Procedural Logic  
**Secção:** SQL Constructs in Databricks  
**Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner

---

## O que é Parameterized SQL?

**Parameterized SQL** torna os notebooks Databricks interactivos através de **Widgets** — controlos de input (dropdowns, campos de texto, multi-selects) que capturam valores do utilizador em runtime e os injectam directamente nas queries SQL.

É o equivalente moderno dos inputs de stored procedures — mas com UI visual e integração com workflows.

**Características principais:**
- Widgets criam controlos interactivos para input do utilizador
- Sintaxe de parâmetro com prefixo `:` (ex: `:region_input`, `:year_input`) para referenciar os valores nas queries
- Integra com workflows como parameterized input (via `base_parameters`)
- Permite lógica dinâmica driven pelo utilizador

> Parameterized SQL simula o comportamento de stored procedure inputs — mas com visibilidade total e suporte de UI.

---

## Os 2 passos do padrão

### Passo 1 — Criar os widgets

```sql
CREATE WIDGET TEXT region_input DEFAULT "AMERICA";
CREATE WIDGET TEXT year_input   DEFAULT "1995";
```

`CREATE WIDGET TEXT` define um campo de input de texto com um valor default. O Databricks renderiza automaticamente controlos de UI no topo do notebook — o utilizador pode alterar os valores sem tocar no código SQL.

Tipos de widget disponíveis:
- `TEXT` — campo de texto livre
- `DROPDOWN` — lista de opções pré-definidas
- `COMBOBOX` — dropdown editável
- `MULTISELECT` — selecção múltipla

### Passo 2 — Referenciar os valores na query

```sql
SELECT ...
WHERE r.r_name = :region_input
  AND year(o.o_orderdate) = :year_input
LIMIT 10;
```

A sintaxe `:nome_widget` injeta o valor directamente na query — exactamente como se tivesses passado um parâmetro a uma stored procedure. O valor muda automaticamente quando o utilizador actualiza o widget.

---

## Anatomia completa

```sql
-- Passo 1: criar widgets com valores default
CREATE WIDGET TEXT region_input DEFAULT "AMERICA";
CREATE WIDGET TEXT year_input   DEFAULT "1995";

-- Passo 2: usar os valores com sintaxe :nome_widget
SELECT
  o.o_orderkey,
  o.o_totalprice,
  o.o_orderdate,
  r.r_name
FROM bronze.orders o
JOIN bronze.customer c  ON o.o_custkey   = c.c_custkey
JOIN bronze.nation   n  ON c.c_nationkey = n.n_nationkey
JOIN bronze.region   r  ON n.n_regionkey = r.r_regionkey
WHERE r.r_name           = :region_input
  AND year(o.o_orderdate) = :year_input
LIMIT 10;
```

---

## Widgets em Workflows (Jobs)

O mesmo mecanismo funciona em jobs — em vez do utilizador definir os valores pela UI, o job passa-os programaticamente via o campo **`base_parameters`** na task do notebook:

```json
{
  "base_parameters": {
    "region_input": "EUROPE",
    "year_input": "1996"
  }
}
```

Isto torna o mesmo notebook reutilizável em múltiplos contextos: interactivo para analistas, automatizado em pipelines.

---

## Parameterized SQL vs EXECUTE IMMEDIATE

| | Parameterized SQL (Widgets) | EXECUTE IMMEDIATE |
|---|---|---|
| **Input** | UI do utilizador / job parameters | Variáveis SQL declaradas no script |
| **Sintaxe** | `:nome_widget` inline na query | `DECLARE` + string + `EXECUTE` |
| **Estrutura da query** | Fixa — só os valores mudam | Dinâmica — a própria query é construída |
| **Nomes de tabelas variáveis** | ❌ Não suporta | ✅ Suporta |
| **Melhor para** | Dashboards, relatórios ad-hoc, input do utilizador | Pipelines, lógica cross-table, scripts administrativos |

> **Regra prática:** se só precisas de mudar **valores** (filtros, datas, regiões) → Parameterized SQL. Se precisas de mudar a **estrutura** da query (nomes de tabelas, colunas, cláusulas) → EXECUTE IMMEDIATE.

---

## Key takeaways

- Widgets transformam notebooks estáticos em **ferramentas interactivas** — sem alterar uma linha de SQL
- A sintaxe `:nome` é limpa e segura — não há risco de SQL injection como na concatenação manual de strings
- O mesmo notebook funciona interactivamente (UI) e em automação (job `base_parameters`) — sem alterações
- São a forma mais acessível de **simular stored procedure inputs** em Databricks SQL
- Perfeitos para dashboards, relatórios ad-hoc, e qualquer workflow onde os valores de input mudam por run
