-- =============================================================================
-- SQL User Defined Functions (UDFs) — Demo Code
-- Módulo: SQL Programming and Procedural Logic
-- Secção: SQL Constructs in Databricks
-- Fonte: Databricks Learning Festival 2026 — Pathway 8
-- =============================================================================
-- Dataset: samples.tpch (Community Edition)
-- As UDFs são persistentes no Unity Catalog — sobrevivem entre sessões.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- CRIAR A UDF
-- Avalia se uma order é "rush" — expedida <= 2 dias após ser colocada
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_rush_order(
  shipdate   DATE,
  order_date DATE
)
RETURNS BOOLEAN
  RETURN datediff(shipdate, order_date) <= 2;


-- -----------------------------------------------------------------------------
-- USAR A UDF NO SELECT — adicionar coluna calculada por linha
-- -----------------------------------------------------------------------------
SELECT
  o.o_orderkey,
  o.o_orderdate,
  l.l_shipdate,
  is_rush_order(l.l_shipdate, o.o_orderdate) AS is_rush
FROM samples.tpch.orders o
JOIN samples.tpch.lineitem l ON o.o_orderkey = l.l_orderkey
LIMIT 20;


-- -----------------------------------------------------------------------------
-- USAR A UDF NO WHERE — filtrar apenas rush orders
-- -----------------------------------------------------------------------------
SELECT
  o.o_orderkey,
  o.o_orderdate,
  l.l_shipdate,
  datediff(l.l_shipdate, o.o_orderdate) AS days_to_ship
FROM samples.tpch.orders o
JOIN samples.tpch.lineitem l ON o.o_orderkey = l.l_orderkey
WHERE is_rush_order(l.l_shipdate, o.o_orderdate) = TRUE
LIMIT 20;


-- -----------------------------------------------------------------------------
-- USAR A UDF NO CASE — classificar orders por tipo
-- -----------------------------------------------------------------------------
SELECT
  o.o_orderkey,
  o.o_totalprice,
  CASE
    WHEN is_rush_order(l.l_shipdate, o.o_orderdate) THEN 'Rush'
    ELSE 'Standard'
  END AS order_type
FROM samples.tpch.orders o
JOIN samples.tpch.lineitem l ON o.o_orderkey = l.l_orderkey
LIMIT 20;


-- -----------------------------------------------------------------------------
-- COMBINAR UDF COM CTE — padrão production-ready
-- Objectivo: contar rush vs standard orders e calcular receita por tipo
-- -----------------------------------------------------------------------------
WITH classified_orders AS (
  SELECT
    o.o_orderkey,
    o.o_totalprice,
    CASE
      WHEN is_rush_order(l.l_shipdate, o.o_orderdate) THEN 'Rush'
      ELSE 'Standard'
    END AS order_type
  FROM samples.tpch.orders o
  JOIN samples.tpch.lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT
  order_type,
  COUNT(DISTINCT o_orderkey) AS total_orders,
  SUM(o_totalprice)          AS total_revenue,
  AVG(o_totalprice)          AS avg_order_value
FROM classified_orders
GROUP BY order_type
ORDER BY total_revenue DESC;


-- -----------------------------------------------------------------------------
-- EXEMPLO ADICIONAL: UDF de classificação com STRING de retorno
-- Categoriza clientes por valor gasto total
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION classify_customer(total_spent DOUBLE)
RETURNS STRING
  RETURN CASE
    WHEN total_spent >= 500000 THEN 'Platinum'
    WHEN total_spent >= 200000 THEN 'Gold'
    WHEN total_spent >= 50000  THEN 'Silver'
    ELSE                            'Bronze'
  END;

-- Usar a UDF de classificação
WITH customer_totals AS (
  SELECT
    o_custkey,
    SUM(o_totalprice) AS total_spent
  FROM samples.tpch.orders
  GROUP BY o_custkey
)
SELECT
  c.c_name,
  ct.total_spent,
  classify_customer(ct.total_spent) AS customer_tier
FROM customer_totals ct
JOIN samples.tpch.customer c ON ct.o_custkey = c.c_custkey
ORDER BY ct.total_spent DESC
LIMIT 20;


-- -----------------------------------------------------------------------------
-- LIMPEZA (opcional)
-- -----------------------------------------------------------------------------
-- DROP FUNCTION IF EXISTS is_rush_order;
-- DROP FUNCTION IF EXISTS classify_customer;

-- =============================================================================
-- Resumo de sintaxe:
--   CREATE OR REPLACE FUNCTION nome(arg TIPO, ...)
--   RETURNS TIPO
--     RETURN expressão;
--
-- Pode ser usado em: SELECT, WHERE, CASE, CTEs, outros UDFs
-- Persiste no Unity Catalog — disponível em qualquer notebook do workspace
-- =============================================================================
