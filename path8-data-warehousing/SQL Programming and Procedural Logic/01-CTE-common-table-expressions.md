# SQL Constructs in Databricks — Common Table Expressions (CTEs)

**Módulo:** SQL Programming and Procedural Logic  
**Secção:** SQL Constructs in Databricks  
**Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner

---

## Contexto: Lógica SQL Modular no Databricks

O Databricks não suporta stored procedures como os RDBMS tradicionais (SQL Server, Oracle). Em vez disso, oferece uma abordagem moderna baseada em **componentes SQL composáveis** — mais flexíveis, testáveis e fáceis de manter.

| Abordagem Tradicional | Abordagem Databricks |
|---|---|
| Stored procedures | CTEs + Workflows (Lakeflow Jobs) |
| Lógica encapsulada na base de dados | Lógica modular em notebooks/queries |
| Difícil de versionar e testar | Compatível com Git, testável por partes |
| Acoplada ao RDBMS | Portável e cloud-native |

> **Objetivo:** simular o comportamento de stored procedures usando componentes SQL flexíveis e testáveis — reduzindo technical debt e modernizando o codebase.

---

## O que é uma CTE?

Uma **Common Table Expression (CTE)** é um bloco de query com nome — um resultado temporário que existe apenas durante a execução da query. Funciona como uma mini-tabela que defines no início e podes referenciar ao longo do resto da query.

**Características principais:**
- Define blocos de query nomeados para lógica SQL em camadas
- Cada cláusula `WITH` age como um passo de processamento
- Útil para **composability**, clareza e reutilização
- Frequentemente usada para fazer staging de transformações de dados

---

## Anatomia de uma CTE

```sql
WITH customer_orders AS (        -- 1. Nome do CTE (view identifier)
  SELECT                         -- 2. Subquery: define o resultado intermédio
    o_custkey,
    COUNT(*) AS num_orders,
    SUM(o_totalprice) AS total_spent
  FROM tpch.orders
  GROUP BY o_custkey             -- pode incluir filtros, joins, agregações
)
SELECT * FROM customer_orders;   -- 3. Query principal: usa o CTE como uma tabela
```

### As três partes:

| Parte | O que faz |
|---|---|
| `WITH nome_cte AS (...)` | Define o resultado temporário — o **view identifier** |
| Subquery dentro dos `()` | Especifica a estrutura de colunas do resultado temporário |
| `SELECT ... FROM nome_cte` | Usa o CTE como se fosse uma tabela normal |

**Nota:** As colunas do resultado são herdadas dos aliases da subquery (`num_orders`, `total_spent`). Podes sobrepô-las explicitamente se quiseres, mas normalmente não é necessário.

---

## Porquê usar CTEs?

### 1. Evitar repetição
Sem CTE, serias obrigada a repetir a lógica de agregação em cada lugar onde precisas dos dados. Com CTE, defines uma vez e referencias pelo nome.

### 2. Clareza e legibilidade
Cada CTE é um passo lógico com um nome descritivo — o código fica auto-documentado.

### 3. Composabilidade
Podes encadear múltiplos CTEs, onde cada um constrói sobre o anterior:

```sql
WITH 
  -- Passo 1: agregar orders por cliente
  customer_orders AS (
    SELECT
      o_custkey,
      COUNT(*) AS num_orders,
      SUM(o_totalprice) AS total_spent
    FROM tpch.orders
    GROUP BY o_custkey
  ),
  -- Passo 2: classificar clientes por valor gasto
  ranked_customers AS (
    SELECT
      o_custkey,
      num_orders,
      total_spent,
      RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM customer_orders          -- <-- referencia o CTE anterior!
  )
-- Query final: só os top 10
SELECT *
FROM ranked_customers
WHERE spending_rank <= 10;
```

---

## CTEs vs outras alternativas

| | CTE | Subquery | Temp View | Tabela |
|---|---|---|---|---|
| **Scope** | Query atual | Query atual | Sessão | Persistente |
| **Reusável** | Dentro da query | ❌ | Na sessão | Sempre |
| **Legibilidade** | ✅ Alta | ❌ Baixa | ✅ Alta | ✅ Alta |
| **Caso de uso** | Lógica intermédia complexa | Filtros simples | Reutilização na sessão | Dados persistentes |

---

## Exercício prático (Community Edition)

No teu Databricks Community Edition, o dataset `tpch` está disponível como sample data. Cria um notebook SQL e experimenta:

```sql
-- Exercício 1: CTE básico
-- Objetivo: listar clientes com mais de 5 orders

WITH customer_orders AS (
  SELECT
    o_custkey,
    COUNT(*) AS num_orders,
    SUM(o_totalprice) AS total_spent
  FROM samples.tpch.orders
  GROUP BY o_custkey
)
SELECT *
FROM customer_orders
WHERE num_orders > 5
ORDER BY total_spent DESC;
```

```sql
-- Exercício 2: CTEs encadeados
-- Objetivo: encontrar os top 5 clientes e juntar com o nome do cliente

WITH 
  customer_orders AS (
    SELECT
      o_custkey,
      COUNT(*) AS num_orders,
      SUM(o_totalprice) AS total_spent
    FROM samples.tpch.orders
    GROUP BY o_custkey
  ),
  top_customers AS (
    SELECT *
    FROM customer_orders
    ORDER BY total_spent DESC
    LIMIT 5
  )
SELECT
  c.c_name,
  t.num_orders,
  t.total_spent
FROM top_customers t
JOIN samples.tpch.customer c ON t.o_custkey = c.c_custkey;
```

> **Nota:** No Community Edition usa o prefixo `samples.tpch.` para aceder às tabelas de exemplo da Databricks.

---

## Key takeaways

- CTEs são a **alternativa moderna às stored procedures** em Databricks — mais limpas, testáveis e versionáveis
- Cada `WITH` é um passo de processamento — pensa em CTEs como a **medalha de bronze/silver de uma única query**
- Podes encadear quantos CTEs precisares — cada um pode referenciar os anteriores
- O scope é **limitado à query** — não persiste entre execuções (para isso usas Temp Views ou tabelas)
