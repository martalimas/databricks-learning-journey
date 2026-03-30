-- ============================================================
-- SQL Scripting in Databricks
-- Pathway 8 · SQL Programming and Procedural Logic
-- Demo: Conditional Logic — IF and CASE
-- Exercise: Categorize Supplier Location
-- ============================================================
-- Goal: Use IF and CASE to classify a supplier's location as
--       'Domestic', 'International', or 'Unlisted'
--
-- Steps:
--   1. DECLARE a variable to hold the supplier's country
--   2. SET the variable via a JOIN between supplier and nation
--   3a. Classify using IF...ELSEIF...ELSE
--   3b. Classify using CASE (same logic, compact form)
--
-- Replace <user_catalog_name> with your actual catalog name
-- ============================================================

BEGIN

    -- Step 1: Declare variable to hold country
    DECLARE supp_country STRING;

    -- Step 2: Get country of supplier 500
    -- Joins supplier with nation to retrieve the country name
    -- for the supplier whose key is 500.
    -- This is a scalar subquery — must return exactly one row.
    SET supp_country = (
        SELECT n.n_name
        FROM <user_catalog_name>.bronze.supplier AS s
        JOIN <user_catalog_name>.bronze.nation   AS n
            ON s.s_nationkey = n.n_nationkey
        WHERE s.s_suppkey = 500
    );

    -- Step 3a: Classification using IF
    -- IF controls execution flow — each branch runs a full SELECT statement.
    -- NULL check must come first (IS NULL), before equality checks.
    IF supp_country IS NULL THEN
        SELECT 'Unlisted' AS classification;

    ELSEIF supp_country = 'USA' THEN
        SELECT 'Domestic' AS classification;

    ELSE
        SELECT 'International' AS classification;

    END IF;

    -- Step 3b: Classification using CASE
    -- CASE produces a value inside a SELECT — same logic, compact form.
    -- Useful when you want a labelled column rather than branched execution.
    SELECT
        CASE
            WHEN supp_country IS NULL    THEN 'Unlisted'
            WHEN supp_country = 'USA'   THEN 'Domestic'
            ELSE                              'International'
        END AS case_classification;

END;

-- ============================================================
-- KEY DIFFERENCES: IF vs. CASE (revisão rápida)
-- ============================================================
-- IF...THEN...ELSE   → controla O QUE O SCRIPT FAZ
--                      cada ramo executa um statement diferente
--                      usa quando: validation, alerts, branching
--
-- CASE               → controla QUE VALOR APARECE numa coluna
--                      vive dentro de um SELECT
--                      usa quando: labeling, categorization em output
-- ============================================================
-- NOTA: NULL check com IS NULL tem de ser o PRIMEIRO WHEN/IF.
-- NULL != 'USA' não é FALSE em SQL — é NULL (unknown),
-- por isso sem o IS NULL explícito o caso Unlisted nunca dispara.
-- ============================================================
