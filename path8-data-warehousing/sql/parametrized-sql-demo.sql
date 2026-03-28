-- =============================================================================
-- Parameterized SQL (Widgets) — Demo Code (lecture slides)
-- Módulo: SQL Programming and Procedural Logic
-- Secção: SQL Constructs in Databricks
-- Fonte: Databricks Learning Festival 2026 — Pathway 8
-- =============================================================================
-- Lab environment : bronze.*
-- Community Edition: substitui bronze.orders   -> samples.tpch.orders
--                                bronze.customer -> samples.tpch.customer
--                                bronze.nation   -> samples.tpch.nation
--                                bronze.region   -> samples.tpch.region
--
-- ✅ Widgets funcionam em SQL Warehouses e clusters (all-purpose)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- PASSO 1: Criar os widgets
-- Databricks renderiza controlos de UI no topo do notebook
-- O utilizador pode alterar os valores sem tocar no código SQL
-- -----------------------------------------------------------------------------
CREATE WIDGET TEXT region_input DEFAULT "AMERICA";
CREATE WIDGET TEXT year_input   DEFAULT "1995";


-- -----------------------------------------------------------------------------
-- PASSO 2: Usar os valores do widget na query com sintaxe :nome_widget
-- Os valores são injectados directamente — mudam quando o widget muda
-- -----------------------------------------------------------------------------
SELECT
  o.o_orderkey,
  o.o_totalprice,
  o.o_orderdate,
  r.r_name AS region
FROM bronze.orders o
JOIN bronze.customer c  ON o.o_custkey    = c.c_custkey
JOIN bronze.nation   n  ON c.c_nationkey  = n.n_nationkey
JOIN bronze.region   r  ON n.n_regionkey  = r.r_regionkey
WHERE r.r_name            = :region_input
  AND year(o.o_orderdate)  = :year_input
LIMIT 10;


-- -----------------------------------------------------------------------------
-- EXEMPLO 2: Widget DROPDOWN para limitar as opções disponíveis
-- Útil quando os valores válidos são conhecidos antecipadamente
-- -----------------------------------------------------------------------------
CREATE WIDGET DROPDOWN status_input
  DEFAULT "F"
  CHOICES SELECT DISTINCT o_orderstatus FROM bronze.orders ORDER BY 1;

SELECT
  o_orderpriority,
  COUNT(*)          AS total_orders,
  SUM(o_totalprice) AS total_revenue
FROM bronze.orders
WHERE o_orderstatus = :status_input
GROUP BY o_orderpriority
ORDER BY total_revenue DESC;


-- -----------------------------------------------------------------------------
-- REMOVER WIDGETS (limpeza)
-- -----------------------------------------------------------------------------
-- REMOVE WIDGET region_input;
-- REMOVE WIDGET year_input;
-- REMOVE WIDGET status_input;


-- =============================================================================
-- Usar widgets em Workflows (Jobs):
--
-- O mesmo notebook funciona em automação via base_parameters na task:
--
-- {
--   "base_parameters": {
--     "region_input": "EUROPE",
--     "year_input":   "1996"
--   }
-- }
--
-- Sintaxe de referência: :nome_widget  (prefixo colon)
-- Tipos disponíveis: TEXT, DROPDOWN, COMBOBOX, MULTISELECT
--
-- ✅ Usa Parameterized SQL quando só os VALORES mudam
-- ✅ Usa EXECUTE IMMEDIATE quando a ESTRUTURA da query muda
-- =============================================================================


-- =============================================================================
-- Parameterized SQL (Widgets) — Lab Code
-- Módulo: SQL Programming and Procedural Logic
-- Secção: SQL Constructs in Databricks
-- Fonte: Databricks Learning Festival 2026 — Pathway 8
-- =============================================================================
-- Lab environment : bronze.*
-- Community Edition: substitui bronze.customer  -> samples.tpch.customer
--                                bronze.orders   -> samples.tpch.orders
--                                bronze.nation   -> samples.tpch.nation
--                                bronze.region   -> samples.tpch.region
--                                bronze.part     -> samples.tpch.part
--                                bronze.lineitem -> samples.tpch.lineitem
--
-- ⚠️  getArgument() está DEPRECATED desde DBR 17.0
--     Usa SEMPRE a sintaxe :param em vez de getArgument("param")
-- =============================================================================


-- -----------------------------------------------------------------------------
-- CELL 31: TEXT widgets — filtrar por região e ano
-- Widgets aparecem como controlos no topo do notebook
-- -----------------------------------------------------------------------------

-- Criar widgets de texto com valores default
CREATE WIDGET TEXT region_input DEFAULT "AMERICA";
CREATE WIDGET TEXT year_input   DEFAULT "1995";

-- Referenciar com sintaxe :nome_widget na query
SELECT
  c.c_name,
  o.o_orderdate,
  o.o_totalprice
FROM bronze.customer c
JOIN bronze.orders  o ON c.c_custkey    = o.o_custkey
JOIN bronze.nation  n ON c.c_nationkey  = n.n_nationkey
JOIN bronze.region  r ON n.n_regionkey  = r.r_regionkey
-- ⚠️  sintaxe antiga (deprecated): WHERE r.r_name = getArgument("region_input")
WHERE r.r_name              = :region_input      -- ✅ sintaxe correcta
  AND year(o.o_orderdate)   = :year_input
LIMIT 10;


-- -----------------------------------------------------------------------------
-- CELL 33 — Iteration 1: TEXT widget com contains() para filtro parcial
-- Objectivo: filtrar produtos cujo p_type contém o material seleccionado
-- contains(coluna, :widget) → TRUE se o widget é substring da coluna
-- -----------------------------------------------------------------------------
CREATE WIDGET TEXT part_material DEFAULT "STEEL";

SELECT
  p.p_name,
  p.p_type,
  SUM(l.l_extendedprice) AS total_sales
FROM bronze.part p
JOIN bronze.lineitem l ON p.p_partkey = l.l_partkey
WHERE contains(p.p_type, :part_material)   -- filtra se p_type contém "STEEL"
GROUP BY p.p_name, p.p_type
ORDER BY total_sales DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- CELL 34 — Iteration 2: MULTISELECT widget
-- Permite seleccionar múltiplos valores — o resultado é uma string
-- com os valores separados por vírgula: "NICKEL,BRASS"
-- CHOICES define as opções disponíveis no dropdown
-- -----------------------------------------------------------------------------
CREATE WIDGET MULTISELECT part_material_multiselect
  DEFAULT ('COPPER')
  CHOICES SELECT * FROM (VALUES ('COPPER'), ('STEEL'), ('ALUMINUM'), ('NICKEL'), ('BRASS'));


-- -----------------------------------------------------------------------------
-- CELL 35: Usar o MULTISELECT com array_contains + split
-- O widget devolve uma string "NICKEL,BRASS" — precisamos converter para array
--
-- Padrão:
--   split(:widget, ',')           → converte "NICKEL,BRASS" em array ['NICKEL','BRASS']
--   split_part(p.p_type, ' ', -1) → extrai o último token de "SMALL BURNISHED NICKEL" → "NICKEL"
--   array_contains(array, valor)  → TRUE se o material está no array seleccionado
-- -----------------------------------------------------------------------------
SELECT
  p.p_name,
  p.p_type,
  SUM(l.l_extendedprice) AS total_sales
FROM bronze.part p
JOIN bronze.lineitem l ON p.p_partkey = l.l_partkey
WHERE array_contains(
    split(:part_material_multiselect, ','),   -- array de materiais seleccionados
    split_part(p.p_type, ' ', -1)             -- último token do p_type (ex: "NICKEL")
  )
GROUP BY p.p_name, p.p_type
ORDER BY total_sales DESC
LIMIT 10;

-- Resultado com NICKEL e BRASS seleccionados:
--   Produtos com p_type terminando em NICKEL ou BRASS, por total_sales DESC


-- =============================================================================
-- Resumo dos widgets do lab:
--
--   TEXT        → CREATE WIDGET TEXT nome DEFAULT "valor";
--                 Referência: :nome
--                 Uso: filtros exactos ou parciais (contains)
--
--   MULTISELECT → CREATE WIDGET MULTISELECT nome DEFAULT ('val') CHOICES SELECT ...;
--                 Referência: :nome  (devolve "val1,val2" como string)
--                 Uso: array_contains(split(:nome, ','), coluna)
--
-- ⚠️  getArgument("param") está DEPRECATED — usa sempre :param
--
-- Passar widgets em Workflows (Jobs):
--   Campo "base_parameters" na task:
--   { "region_input": "EUROPE", "year_input": "1996" }
-- =============================================================================

