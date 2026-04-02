-- =============================================================================
-- Data Vault 2.0 — Exemplos de DDL
-- Estruturas Hub, Link, Satellite com mapeamento Bronze/Silver/Gold
-- =============================================================================

-- =============================================================================
-- CAMADA SILVER — Raw Vault
-- =============================================================================

USE silver;

-- ------------------------------------------------
-- HUB: entidade de negócio central
-- Contém apenas: surrogate key, business key,
-- load_date e record_source
-- ------------------------------------------------

CREATE TABLE IF NOT EXISTS Hub_Customer (
    hub_customer_key  BIGINT GENERATED ALWAYS AS IDENTITY,  -- Surrogate key interna
    customer_id       STRING    NOT NULL,   -- Business Key (chave natural, estável e única)
    load_date         TIMESTAMP NOT NULL,   -- Data/hora de ingestão
    record_source     STRING    NOT NULL,   -- Origem do registo (e.g., 'CRM', 'ERP')
    CONSTRAINT pk_hub_customer PRIMARY KEY (hub_customer_key)
);

CREATE TABLE IF NOT EXISTS Hub_Product (
    hub_product_key  BIGINT GENERATED ALWAYS AS IDENTITY,
    product_sku      STRING    NOT NULL,   -- Business Key do produto
    load_date        TIMESTAMP NOT NULL,
    record_source    STRING    NOT NULL,
    CONSTRAINT pk_hub_product PRIMARY KEY (hub_product_key)
);

CREATE TABLE IF NOT EXISTS Hub_Order (
    hub_order_key  BIGINT GENERATED ALWAYS AS IDENTITY,
    order_id       STRING    NOT NULL,     -- Business Key da encomenda
    load_date      TIMESTAMP NOT NULL,
    record_source  STRING    NOT NULL,
    CONSTRAINT pk_hub_order PRIMARY KEY (hub_order_key)
);

-- ------------------------------------------------
-- LINK: relação many-to-many entre Hubs
-- Contém: surrogate key, FKs dos Hubs,
-- load_date e record_source
-- ------------------------------------------------

-- Relação: Customer compra Product (via Order)
CREATE TABLE IF NOT EXISTS Link_CustomerOrder (
    link_customer_order_key  BIGINT GENERATED ALWAYS AS IDENTITY,
    hub_customer_key         BIGINT    NOT NULL,   -- FK → Hub_Customer
    hub_order_key            BIGINT    NOT NULL,   -- FK → Hub_Order
    load_date                TIMESTAMP NOT NULL,
    record_source            STRING    NOT NULL,
    CONSTRAINT pk_link_customer_order PRIMARY KEY (link_customer_order_key),
    CONSTRAINT fk_lco_customer FOREIGN KEY (hub_customer_key) REFERENCES Hub_Customer(hub_customer_key),
    CONSTRAINT fk_lco_order    FOREIGN KEY (hub_order_key)    REFERENCES Hub_Order(hub_order_key)
);

-- Relação: Order contém Product
CREATE TABLE IF NOT EXISTS Link_OrderProduct (
    link_order_product_key  BIGINT GENERATED ALWAYS AS IDENTITY,
    hub_order_key           BIGINT    NOT NULL,   -- FK → Hub_Order
    hub_product_key         BIGINT    NOT NULL,   -- FK → Hub_Product
    load_date               TIMESTAMP NOT NULL,
    record_source           STRING    NOT NULL,
    CONSTRAINT pk_link_order_product PRIMARY KEY (link_order_product_key),
    CONSTRAINT fk_lop_order   FOREIGN KEY (hub_order_key)   REFERENCES Hub_Order(hub_order_key),
    CONSTRAINT fk_lop_product FOREIGN KEY (hub_product_key) REFERENCES Hub_Product(hub_product_key)
);

-- ------------------------------------------------
-- SATELLITE: atributos descritivos + histórico
-- Cada nova versão = nova linha (não UPDATE)
-- end_date NULL = registo activo
-- ------------------------------------------------

-- Satellite de dados demográficos do cliente
CREATE TABLE IF NOT EXISTS Sat_Customer_Demographics (
    sat_cust_demo_key  BIGINT GENERATED ALWAYS AS IDENTITY,
    hub_customer_key   BIGINT    NOT NULL,   -- FK → Hub_Customer
    name               STRING,
    address            STRING,
    phone              STRING,
    market_segment     STRING,
    load_date          TIMESTAMP NOT NULL,   -- Início de validade (versão activa a partir daqui)
    end_date           TIMESTAMP,            -- Fim de validade (NULL = registo actual)
    record_source      STRING    NOT NULL,
    CONSTRAINT pk_sat_cust_demo PRIMARY KEY (sat_cust_demo_key),
    CONSTRAINT fk_scd_customer  FOREIGN KEY (hub_customer_key) REFERENCES Hub_Customer(hub_customer_key)
);

-- Satellite de dados financeiros do cliente (frequência de update diferente → Satellite separado)
CREATE TABLE IF NOT EXISTS Sat_Customer_Financials (
    sat_cust_fin_key  BIGINT GENERATED ALWAYS AS IDENTITY,
    hub_customer_key  BIGINT         NOT NULL,
    acct_bal          DECIMAL(12, 2),
    credit_rating     STRING,
    load_date         TIMESTAMP      NOT NULL,
    end_date          TIMESTAMP,
    record_source     STRING         NOT NULL,
    CONSTRAINT pk_sat_cust_fin  PRIMARY KEY (sat_cust_fin_key),
    CONSTRAINT fk_scf_customer  FOREIGN KEY (hub_customer_key) REFERENCES Hub_Customer(hub_customer_key)
);

-- Satellite de atributos de encomenda (ligado ao Link, não ao Hub)
CREATE TABLE IF NOT EXISTS Sat_CustomerOrder_Details (
    sat_co_details_key       BIGINT GENERATED ALWAYS AS IDENTITY,
    link_customer_order_key  BIGINT         NOT NULL,   -- FK → Link_CustomerOrder
    total_price              DECIMAL(12, 2),
    order_status             STRING,
    order_priority           STRING,
    order_date               DATE,
    load_date                TIMESTAMP      NOT NULL,
    end_date                 TIMESTAMP,
    record_source            STRING         NOT NULL,
    CONSTRAINT pk_sat_co_details PRIMARY KEY (sat_co_details_key),
    CONSTRAINT fk_scod_link      FOREIGN KEY (link_customer_order_key) REFERENCES Link_CustomerOrder(link_customer_order_key)
);


-- =============================================================================
-- CAMADA SILVER — Business Vault
-- (Business rules aplicadas; vistas e tabelas derivadas)
-- =============================================================================

-- PIT Table (Point-in-Time): consolida múltiplos Satellites num único ponto temporal
-- Facilita queries históricas sem JOINs complexos
CREATE TABLE IF NOT EXISTS PIT_Customer (
    pit_customer_key       BIGINT GENERATED ALWAYS AS IDENTITY,
    hub_customer_key       BIGINT    NOT NULL,
    snapshot_date          DATE      NOT NULL,  -- Data do snapshot
    -- Referências à versão activa de cada Satellite nessa data:
    sat_cust_demo_key      BIGINT,              -- FK → Sat_Customer_Demographics
    sat_cust_fin_key       BIGINT,              -- FK → Sat_Customer_Financials
    CONSTRAINT pk_pit_customer PRIMARY KEY (pit_customer_key)
);

-- Business View: exemplo de vista que aplica regras de negócio
-- (normalmente criada como VIEW, não como tabela física)
-- CREATE OR REPLACE VIEW bv_active_customers AS
-- SELECT
--     h.customer_id,
--     sd.name,
--     sd.address,
--     sd.market_segment,
--     sf.acct_bal
-- FROM Hub_Customer h
-- JOIN Sat_Customer_Demographics sd
--     ON  h.hub_customer_key = sd.hub_customer_key
--     AND sd.end_date IS NULL   -- versão activa
-- JOIN Sat_Customer_Financials sf
--     ON  h.hub_customer_key = sf.hub_customer_key
--     AND sf.end_date IS NULL;  -- versão activa


-- =============================================================================
-- CARGA INCREMENTAL — padrão de INSERT para Satellites (SCD nativo)
-- Nova versão = fechar registo anterior + inserir novo
-- =============================================================================

-- 1. Fechar registo anterior do Satellite
UPDATE Sat_Customer_Demographics
SET end_date = CURRENT_TIMESTAMP()
WHERE hub_customer_key = (
    SELECT hub_customer_key FROM Hub_Customer WHERE customer_id = '101'
)
AND end_date IS NULL;

-- 2. Inserir nova versão
INSERT INTO Sat_Customer_Demographics
    (hub_customer_key, name, address, phone, market_segment, load_date, end_date, record_source)
VALUES (
    (SELECT hub_customer_key FROM Hub_Customer WHERE customer_id = '101'),
    'CHANGED Name',
    'Updated Address 500',
    '555-NEW-8888',
    'NEW_SEGMENT',
    CURRENT_TIMESTAMP(),
    NULL,             -- NULL = registo activo
    'CRM_v2'
);


-- =============================================================================
-- QUERIES DE VALIDAÇÃO
-- =============================================================================

-- Contagem de registos em cada componente do Raw Vault
SELECT 'Hub_Customer'              AS componente, COUNT(*) AS registos FROM Hub_Customer
UNION ALL
SELECT 'Hub_Product',               COUNT(*) FROM Hub_Product
UNION ALL
SELECT 'Hub_Order',                 COUNT(*) FROM Hub_Order
UNION ALL
SELECT 'Link_CustomerOrder',        COUNT(*) FROM Link_CustomerOrder
UNION ALL
SELECT 'Link_OrderProduct',         COUNT(*) FROM Link_OrderProduct
UNION ALL
SELECT 'Sat_Customer_Demographics', COUNT(*) FROM Sat_Customer_Demographics
UNION ALL
SELECT 'Sat_Customer_Financials',   COUNT(*) FROM Sat_Customer_Financials;

-- Verificar histórico SCD de um cliente específico
SELECT
    sd.sat_cust_demo_key,
    h.customer_id,
    sd.name,
    sd.address,
    sd.load_date,
    sd.end_date,
    CASE WHEN sd.end_date IS NULL THEN 'ACTIVO' ELSE 'HISTÓRICO' END AS status
FROM Hub_Customer h
JOIN Sat_Customer_Demographics sd
    ON h.hub_customer_key = sd.hub_customer_key
WHERE h.customer_id = '101'
ORDER BY sd.load_date;
