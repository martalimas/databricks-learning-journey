-- =============================================================================
-- CTEs in Databricks SQL — Demo Code
-- Módulo: SQL Programming and Procedural Logic
-- Secção: SQL Constructs in Databricks
-- Fonte: Databricks Learning Festival 2026 — Pathway 8
-- =============================================================================
-- Dataset: samples.tpch (Community Edition) | bronze.* (lab environment)
-- No Community Edition substitui bronze.orders -> samples.tpch.orders
--                              bronze.customer -> samples.tpch.customer
--                              bronze.nation   -> samples.tpch.nation
--                              bronze.region   -> samples.tpch.region
-- =============================================================================


-- -----------------------------------------------------------------------------
-- STEP 1: Layered CTEs — Rank customers by average order value
-- -----------------------------------------------------------------------------
-- 3 CTEs encadeados:
--   customer_orders  → agrega orders por cliente
--   customer_avg     → calcula valor médio por order
--   ranked_customers → classifica clientes por valor médio (DESC)

WITH customer_orders AS (
  -- Aggregate total and count of orders per customer
  SELECT
    o_custkey,
    COUNT(*) AS num_orders,
    SUM(o_totalprice) AS total_spent
  FROM samples.tpch.orders
  GROUP BY o_custkey
),
customer_avg AS (
  -- Compute the average order value for each customer
  SELECT
    o_custkey,
    total_spent / num_orders AS avg_order_value
  FROM customer_orders
),
ranked_customers AS (
  -- Rank customers by average order value (descending)
  SELECT
    ca.o_custkey,
    ca.avg_order_value,
    RANK() OVER (ORDER BY ca.avg_order_value DESC) AS rank
  FROM customer_avg ca
)
-- Join to customer table to retrieve names
SELECT
  c.c_name,
  rc.avg_order_value,
  rc.rank
FROM ranked_customers rc
JOIN samples.tpch.customer c ON c.c_custkey = rc.o_custkey
WHERE rc.rank <= 10;


-- -----------------------------------------------------------------------------
-- STEP 2: Normalize customer averages by regional average
-- -----------------------------------------------------------------------------
-- 5 CTEs encadeados — cada um constrói sobre o anterior:
--   customer_orders  → agrega orders por cliente
--   customer_avg     → calcula valor médio por order
--   customer_region  → junta cliente à sua região (via nation → region)
--   region_avg       → calcula valor médio por região
--   normalized_scores → normaliza o valor do cliente contra a média regional
--
-- Caso de uso: análise comparativa — como se posiciona cada cliente
-- relativamente à média da sua região?

WITH customer_orders AS (
  -- Aggregate total and count of orders per customer
  SELECT
    o_custkey,
    COUNT(*) AS num_orders,
    SUM(o_totalprice) AS total_spent
  FROM samples.tpch.orders
  GROUP BY o_custkey
),
customer_avg AS (
  -- Compute average order value per customer
  SELECT
    o_custkey,
    total_spent / num_orders AS avg_order_value
  FROM customer_orders
),
customer_region AS (
  -- Join customers to their region (customer → nation → region)
  SELECT
    ca.o_custkey,
    ca.avg_order_value,
    r.r_name AS region_name
  FROM customer_avg ca
  JOIN samples.tpch.customer c  ON ca.o_custkey   = c.c_custkey
  JOIN samples.tpch.nation   n  ON c.c_nationkey  = n.n_nationkey
  JOIN samples.tpch.region   r  ON n.n_regionkey  = r.r_regionkey
),
region_avg AS (
  -- Calculate average order value per region
  SELECT
    region_name,
    AVG(avg_order_value) AS region_avg_order_value
  FROM customer_region
  GROUP BY region_name
),
normalized_scores AS (
  -- Compute normalized score: customer avg / region avg
  SELECT
    cr.o_custkey,
    cr.avg_order_value,
    cr.region_name,
    ra.region_avg_order_value,
    cr.avg_order_value / ra.region_avg_order_value AS normalized_score
  FROM customer_region cr
  JOIN region_avg ra ON cr.region_name = ra.region_name
)
-- Final output: top 10 customers ranked by normalized score
SELECT
  c.c_name,
  ns.region_name,
  ns.avg_order_value,
  ns.region_avg_order_value,
  ns.normalized_score,
  RANK() OVER (ORDER BY ns.normalized_score DESC) AS rank
FROM normalized_scores ns
JOIN samples.tpch.customer c ON ns.o_custkey = c.c_custkey
WHERE ns.normalized_score IS NOT NULL
LIMIT 10;

-- =============================================================================
-- Por que usar CTEs aqui?
-- Sem CTEs, esta lógica seria extremamente difícil de ler ou manter.
-- Cada passo de transformação é independentemente testável e reutilizável.
-- Esta é uma skill crítica para simular stored procedure-like logic em Databricks SQL.
-- =============================================================================
