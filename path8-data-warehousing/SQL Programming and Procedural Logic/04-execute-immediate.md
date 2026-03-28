# SQL Constructs in Databricks — EXECUTE IMMEDIATE

**Módulo:** SQL Programming and Procedural Logic  
**Secção:** SQL Constructs in Databricks  
**Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner

---

## O que é EXECUTE IMMEDIATE?

`EXECUTE IMMEDIATE` permite **construir uma query SQL como string em runtime e executá-la dinamicamente**. É útil sempre que a **estrutura da query precisa de mudar** com base em input — por exemplo, para apontar para uma tabela diferente, aplicar um filtro variável, ou adaptar lógica condicional entre diferentes job runs ou workflows.

**Características principais:**
- Monta SQL usando variáveis de input
- Executa dinamicamente em runtime
- Ideal para nomes de objectos variáveis (tabelas, schemas), filtros, ou lógica de colunas
- Os valores das variáveis podem ser passados via workflows (job parameters)

> É a base do **dynamic SQL em Databricks** — especialmente poderoso quando usado com job parameters ou widgets.

---

## Os 3 passos do padrão EXECUTE IMMEDIATE

### Passo 1 — Declarar as variáveis de input

```sql
DECLARE OR REPLACE table_name   STRING DEFAULT "bronze.orders";
DECLARE OR REPLACE status_filter STRING DEFAULT "F";
```

As variáveis são os **knobs and levers** — os pontos de controlo que tornam o script adaptável. Os valores default podem ser sobrescritos por job parameters ou widgets em runtime.

> No TPCH, `'F'` significa **Finalized** — orders que chegaram ao estado final.

### Passo 2 — Construir a query string

```sql
DECLARE OR REPLACE sqlStr STRING DEFAULT
  "SELECT o_orderpriority, COUNT(*) AS num_orders " ||
  "FROM (?) WHERE o_orderstatus = (?) " ||
  "GROUP BY o_orderpriority";
```

A string é montada com o operador de concatenação `||`. Os `(?)` são **placeholders** — serão substituídos pelos valores das variáveis no passo seguinte.

Esta separação entre **query logic** e **execution logic** torna os notebooks mais adaptáveis a diferentes inputs e workflows.

### Passo 3 — Executar com EXECUTE IMMEDIATE

```sql
EXECUTE IMMEDIATE sqlStr
  USING table_name, status_filter;
```

A cláusula `USING` injeta os valores das variáveis nos placeholders `(?)` pela ordem em que são declarados. Isto garante que o **parameter binding acontece de forma segura** — não precisas de injetar os valores manualmente na string, o que reduz erros e mantém o código limpo.

---

## Anatomia completa

```sql
-- 1. Declarar variáveis
DECLARE OR REPLACE table_name    STRING DEFAULT "bronze.orders";
DECLARE OR REPLACE status_filter STRING DEFAULT "F";

-- 2. Construir a query string com placeholders
DECLARE OR REPLACE sqlStr STRING DEFAULT
  "SELECT o_orderpriority, COUNT(*) AS num_orders " ||
  "FROM (?) WHERE o_orderstatus = (?) " ||
  "GROUP BY o_orderpriority";

-- 3. Executar dinamicamente
EXECUTE IMMEDIATE sqlStr
  USING table_name, status_filter;
```

| Parte | Papel |
|---|---|
| `DECLARE OR REPLACE` | Declara variáveis — os inputs configuráveis |
| `\|\|` | Concatenação de strings para montar a query |
| `(?)` | Placeholders substituídos pelos valores do `USING` |
| `EXECUTE IMMEDIATE` | Executa a string como SQL |
| `USING` | Injeta os valores nos placeholders de forma segura |

---

## Quando usar EXECUTE IMMEDIATE

| Cenário | Exemplo |
|---|---|
| Nome de tabela variável | Correr a mesma query em `bronze`, `silver` ou `gold` |
| Filtro dinâmico | Mudar o status filter entre job runs |
| Lógica cross-environment | Dev vs staging vs prod |
| Dashboards com input do utilizador | Filtrar por região, data, ou categoria |
| Batch processing | Correr a mesma lógica sobre múltiplas tabelas |

---

## ⚠️ Boas práticas e avisos

- **Valida sempre os valores das variáveis** antes de os injetar — especialmente se vierem de input externo
- **Cuidado com aspas** ao construir strings dinâmicas — é a fonte mais comum de erros
- O `USING` é preferível a concatenar valores directamente na string — é mais seguro e legível
- `EXECUTE IMMEDIATE` é poderoso mas deve ser usado com parcimónia — se a query não precisa de ser dinâmica, não o uses

---

## Key takeaways

- `EXECUTE IMMEDIATE` separa **query logic** de **execution logic** — tornando scripts portáveis e adaptáveis
- O padrão tem sempre 3 passos: declarar variáveis → construir string → executar com `USING`
- É a ferramenta certa quando o **nome de um objecto** (tabela, schema) precisa de ser variável — algo que CTEs, Temp Views e UDFs não conseguem fazer
- Usado com job parameters ou widgets, torna qualquer notebook num script reutilizável em múltiplos contextos
- É o padrão mais próximo de **stored procedure behavior** em Databricks SQL
