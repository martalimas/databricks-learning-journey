-- =============================================================================
-- SQL User Defined Functions (UDFs) — Lab Code
-- Módulo: SQL Programming and Procedural Logic
-- Secção: SQL Constructs in Databricks
-- Fonte: Databricks Learning Festival 2026 — Pathway 8
-- =============================================================================
-- Lab environment : bronze.*
-- Community Edition: substitui bronze.lineitem -> samples.tpch.lineitem
--                                bronze.orders  -> samples.tpch.orders
-- =============================================================================


-- -----------------------------------------------------------------------------
-- CELL 19: UDF is_rush_order + uso com CTE
-- Detecta orders expedidas <= 2 dias após serem colocadas
--
-- Padrão do lab: criar a UDF e usá-la imediatamente na mesma célula
-- A CTE calcula o MIN(shipdate) por order — o "earliest shipment"
-- A query final aplica a UDF sobre esse valor mínimo
-- -----------------------------------------------------------------------------

-- Define a UDF que detecta rush orders
CREATE OR REPLACE FUNCTION is_rush_order(shipdate DATE, orderdate DATE)
RETURNS BOOLEAN
  RETURN datediff(shipdate, orderdate) <= 2;

-- Usa a UDF num SELECT com CTE para minimum shipdate
WITH min_shipdate_cte AS (
  SELECT
    l_orderkey,
    MIN(l_shipdate) AS min_shipdate
  FROM bronze.lineitem
  GROUP BY l_orderkey
)
SELECT
  o.o_orderkey,
  o.o_orderdate,
  m.min_shipdate,
  o.o_shippriority,
  is_rush_order(m.min_shipdate, o.o_orderdate) AS is_rush
FROM bronze.orders o
JOIN min_shipdate_cte m ON o.o_orderkey = m.l_orderkey
WHERE o.o_orderstatus = '0'
LIMIT 100;

-- Resultado esperado: coluna is_rush com TRUE/FALSE por linha


-- -----------------------------------------------------------------------------
-- CELL 21 — Iteration 1: Scoring Orders Based on Delivery Timing
-- Segunda UDF com CASE expression — retorna INT em vez de BOOLEAN
--
-- Scoring:
--   2 = Rush     (shipped in 2 days or fewer)
--   1 = On-time  (within 3-5 days)
--   0 = Late     (more than 5 days)
-- -----------------------------------------------------------------------------

-- Define a UDF de scoring com CASE
CREATE OR REPLACE FUNCTION delivery_score(shipdate DATE, orderdate DATE)
RETURNS INT
  RETURN CASE
    WHEN datediff(shipdate, orderdate) <= 2            THEN 2
    WHEN datediff(shipdate, orderdate) BETWEEN 3 AND 5 THEN 1
    ELSE 0
  END;

-- Usa a UDF para analisar distribuição de orders por score
-- CTE para minimum shipdate por order (mesmo padrão da célula anterior)
WITH min_shipdate_cte AS (
  SELECT
    l_orderkey,
    MIN(l_shipdate) AS min_shipdate
  FROM bronze.lineitem
  GROUP BY l_orderkey
)
SELECT
  delivery_score(m.min_shipdate, o.o_orderdate) AS score,
  COUNT(*) AS order_count
FROM bronze.orders o
JOIN min_shipdate_cte m ON o.o_orderkey = m.l_orderkey
WHERE o.o_orderstatus = '0'
GROUP BY score
ORDER BY score DESC;

-- Resultado esperado (valores aproximados do lab):
--   score 2 →  228,472 orders  (Rush)
--   score 1 →  315,508 orders  (On-time)
--   score 0 → 3,110,330 orders (Late)


-- =============================================================================
-- 💡 Tip do lab:
-- UDFs make your SQL modular and testable — especially important for enforcing
-- business rules in shared environments like dashboards, jobs, or views.
-- =============================================================================
