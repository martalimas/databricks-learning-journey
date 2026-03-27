-- =============================================================================
-- Temporary Views in Databricks SQL — Lab Code
-- Módulo: SQL Programming and Procedural Logic
-- Secção: SQL Constructs in Databricks
-- Fonte: Databricks Learning Festival 2026 — Pathway 8
-- =============================================================================
-- Lab environment : bronze.*  (USE CATALOG ... / USE SCHEMA bronze)
-- Community Edition: substitui bronze.lineitem -> samples.tpch.lineitem
--                                bronze.orders  -> samples.tpch.orders
--
-- ⚠️  GLOBAL TEMP VIEW não é compatível com SQL Warehouses nem serverless
--     compute — tem de ser executada num Databricks cluster (all-purpose).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- CELL 11: TEMP VIEW — session-scoped
-- Objetivo: identificar envios tardios (shipdate posterior ao commitdate)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TEMP VIEW late_shipments AS
SELECT
  l_orderkey,
  l_shipdate,
  l_commitdate
FROM bronze.lineitem
WHERE l_shipdate > l_commitdate;


-- -----------------------------------------------------------------------------
-- CELL 12: Usar a TEMP VIEW numa query de follow-up
-- A view comporta-se exactamente como uma tabela normal
-- -----------------------------------------------------------------------------
SELECT * FROM late_shipments
LIMIT 10;


-- -----------------------------------------------------------------------------
-- CELL 13: GLOBAL TEMP VIEW — persiste entre sessões no mesmo cluster
-- Nota: usa l_receiptdate (data de recepção) em vez de l_shipdate
-- Deve ser acedida com o prefixo global_temp
-- ⚠️  Não compatível com SQL Warehouses / serverless — requer cluster
-- -----------------------------------------------------------------------------
CREATE OR REPLACE GLOBAL TEMP VIEW late_shipments_global AS
SELECT
  l_orderkey,
  l_receiptdate,
  l_commitdate
FROM bronze.lineitem
WHERE l_receiptdate > l_commitdate;


-- -----------------------------------------------------------------------------
-- CELL 14: Aceder à Global Temp View
-- SEMPRE com o prefixo global_temp.<nome>
-- -----------------------------------------------------------------------------
SELECT * FROM global_temp.late_shipments_global
LIMIT 10;


-- -----------------------------------------------------------------------------
-- CELL 16: Iteration — Join TEMP VIEW com a tabela orders
-- Objetivo: estimar o impacto em receita dos envios tardios
-- (quanto revenue estava associado a orders com envios atrasados)
-- -----------------------------------------------------------------------------
SELECT
  o.o_orderkey,
  o.o_totalprice,
  o.o_orderdate,
  l.l_shipdate
FROM bronze.orders o
JOIN late_shipments l
  ON o.o_orderkey = l.l_orderkey
LIMIT 10;


-- =============================================================================
-- ⚠️  NOTA IMPORTANTE: Comportamento em Workflows
--
-- TEMP VIEW objects são session-scoped.
-- Se as usares num workflow task, toda a cadeia tem de estar
-- dentro de uma única task ou cluster session.
--
-- ✅ Para workflows cross-task:
--    → Usa GLOBAL TEMP VIEW
--    → Ou persiste os resultados intermédios numa Delta table
-- =============================================================================
