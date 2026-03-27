# SQL Constructs in Databricks — User Defined Functions (UDFs)


segundo exemplo no SQL — classify_customer — que retorna uma STRING em vez de BOOLEAN, mostrando o padrão mais comum em data warehousing: categorizar clientes por tier. Combinado com uma CTE em cima, já é um padrão production-ready.
Uma distinção importante do markdown a memorizar para o exame: UDFs são persistentes no Unity Catalog — ao contrário de CTEs e Temp Views, não desaparecem quando a sessão acaba. São lógica centralizada de verdade.


**Módulo:** SQL Programming and Procedural Logic  
**Secção:** SQL Constructs in Databricks  
**Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner

---

## O que são SQL UDFs?

Uma **User Defined Function (UDF)** permite encapsular lógica reutilizável numa função com nome — que depois podes chamar em qualquer query SQL, exactamente como uma função built-in (`COUNT`, `SUM`, `DATEDIFF`, etc.).

São especialmente valiosas para **operações row-level** — lógica de negócio, risk scoring, classificação — onde a mesma expressão seria repetida em múltiplas queries.

**Características principais:**
- Definem lógica reutilizável a nível de linha (row-level)
- Aceitam argumentos tipados e retornam um único valor (scalar)
- Podem ser referenciadas em qualquer query SQL do workspace
- Ideais para simplificação e portabilidade de lógica de transformação

> Uma vez criada, a UDF fica disponível em qualquer notebook, dashboard ou query do workspace Databricks — é lógica centralizada e standardizada.

---

## Anatomia de uma SQL UDF

```sql
CREATE OR REPLACE FUNCTION          -- 1. Cria ou substitui a função
  is_rush_order(                    -- 2. Nome da função
    shipdate   DATE,                -- 3. Argumentos (nome + tipo)
    order_date DATE
  )
RETURNS BOOLEAN                     -- 4. Tipo de retorno
  RETURN datediff(shipdate, order_date) <= 2;  -- 5. Lógica (expressão RETURN)
```

### As cinco partes:

| Parte | O que faz |
|---|---|
| `CREATE OR REPLACE FUNCTION nome` | Cria a UDF — substitui se já existir |
| `(argumento TIPO, ...)` | Define os inputs com tipos explícitos |
| `RETURNS TIPO` | Declara o tipo de valor que a função devolve |
| `RETURN expressão` | A lógica em si — pode usar qualquer função built-in, operador ou lógica aninhada |
| Resultado | Um **único valor escalar** por linha — nunca uma tabela |

### O exemplo em detalhe:

A função `is_rush_order` avalia se uma order foi expedida menos de 2 dias após ser colocada:
- Se `datediff(shipdate, order_date) <= 2` → devolve `TRUE`
- Caso contrário → devolve `FALSE`

Esta expressão corre **uma vez por linha** — tornando-a perfeita dentro de `SELECT`, `WHERE`, ou como parte de uma expressão `CASE`.

---

## Onde usar UDFs

```sql
-- No SELECT — adicionar uma coluna calculada
SELECT
  o_orderkey,
  o_orderdate,
  l_shipdate,
  is_rush_order(l_shipdate, o_orderdate) AS is_rush
FROM samples.tpch.orders o
JOIN samples.tpch.lineitem l ON o.o_orderkey = l.l_orderkey;

-- No WHERE — filtrar com a lógica da função
SELECT *
FROM samples.tpch.orders o
JOIN samples.tpch.lineitem l ON o.o_orderkey = l.l_orderkey
WHERE is_rush_order(l_shipdate, o_orderdate) = TRUE;

-- No CASE — como parte de lógica condicional
SELECT
  o_orderkey,
  CASE
    WHEN is_rush_order(l_shipdate, o_orderdate) THEN 'Rush'
    ELSE 'Standard'
  END AS order_type
FROM samples.tpch.orders o
JOIN samples.tpch.lineitem l ON o.o_orderkey = l.l_orderkey;
```

---

## UDFs vs outras alternativas

| | UDF | CTE | Temp View |
|---|---|---|---|
| **Scope** | Workspace inteiro | Uma query | Sessão |
| **Reutilização** | Qualquer query, qualquer notebook | Dentro da mesma query | Na sessão atual |
| **Opera sobre** | Valores de uma linha | Conjuntos de resultados | Conjuntos de resultados |
| **Retorna** | Um valor escalar | Uma tabela temporária | Uma tabela temporária |
| **Melhor para** | Lógica de negócio row-level | Transformações intermédias | Staging cross-query |

---

## Tipos de retorno suportados

UDFs SQL no Databricks podem retornar qualquer tipo SQL standard:

`BOOLEAN`, `INT`, `BIGINT`, `DOUBLE`, `STRING`, `DATE`, `TIMESTAMP`, `DECIMAL`, etc.

---

## Key takeaways

- UDFs são a forma de **centralizar regras de negócio** em SQL — defines uma vez, aplicas em todo o lado
- Operam **row-by-row** — um valor de retorno por linha, não por grupo
- São **persistentes** no Unity Catalog — ao contrário de CTEs e Temp Views, sobrevivem entre sessões e notebooks
- O corpo da função usa `RETURN` (não `SELECT`) e pode incluir qualquer expressão SQL válida
- São ideais quando a mesma lógica complexa precisaria de ser repetida em múltiplas queries ou por múltiplos utilizadores
- Tornam queries **mais curtas, legíveis e fáceis de manter** — um pilar de SQL modular e production-ready
- 
