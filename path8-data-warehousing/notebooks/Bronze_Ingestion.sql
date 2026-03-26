-- ============================================================
-- Bronze_Ingestion.sql
-- Ingestão de dados em bruto para a camada Bronze
-- Simula chegada de ficheiros CSV de fontes externas
-- ============================================================

-- Célula 1: Configuração
USE CATALOG tpcdi_learning;
USE SCHEMA bronze;

-- Célula 2: Limpar dados anteriores (simula nova ingestão)
TRUNCATE TABLE bronze.raw_customers;
TRUNCATE TABLE bronze.raw_trades;
TRUNCATE TABLE bronze.raw_securities;

-- Célula 3: Ingerir clientes (simula ficheiro CSV a chegar)
-- NOTA: cliente 1 duplicado propositadamente (vem em dois ficheiros)
INSERT INTO bronze.raw_customers VALUES
('1', 'Ana Silva',    'ana@email.com',   '912345678', 'Lisboa',  'PT', 'ACTIVE',   '20230115', 'customers_jan.csv', current_timestamp()),
('2', 'João Costa',   'joao@email.com',  '913456789', 'Porto',   'PT', 'ACTIVE',   '20230210', 'customers_jan.csv', current_timestamp()),
('3', 'Maria Santos', 'maria@email.com', '914567890', 'Braga',   'PT', 'INACTIVE', '20220305', 'customers_jan.csv', current_timestamp()),
('4', 'Pierre Dupont','pierre@email.com','614567890', 'Paris',   'FR', 'ACTIVE',   '20230401', 'customers_jan.csv', current_timestamp()),
('5', 'Hans Müller',  'hans@email.com',  '714567890', 'Berlim',  'DE', 'ACTIVE',   '20230512', 'customers_jan.csv', current_timestamp()),
('1', 'Ana Silva',    'ana@email.com',   '912345678', 'Lisboa',  'PT', 'ACTIVE',   '20230115', 'customers_fev.csv', current_timestamp()); -- duplicado!

-- Célula 4: Ingerir securities
INSERT INTO bronze.raw_securities VALUES
('S1', 'EDP',  'EDP Renováveis',  'Energia',    'Euronext', 'securities.csv', current_timestamp()),
('S2', 'AAPL', 'Apple Inc',       'Tecnologia', 'NASDAQ',   'securities.csv', current_timestamp()),
('S3', 'BCP',  'Millennium BCP',  'Banca',      'Euronext', 'securities.csv', current_timestamp()),
('S4', 'TSLA', 'Tesla Inc',       'Tecnologia', 'NASDAQ',   'securities.csv', current_timestamp());

-- Célula 5: Ingerir trades (com problemas propositados!)
-- T004: sinal negativo no fim (formato asiático: 210.50- = -210.50)
-- T006: preço vazio
-- T007: customer_id 9 não existe na dim_customers
INSERT INTO bronze.raw_trades VALUES
('T001', '1', 'S1', '20240115', '100',  '15.50',   'BUY',  'COMPLETED', 'trades_jan.csv', current_timestamp()),
('T002', '2', 'S2', '20240116', '50',   '185.00',  'BUY',  'COMPLETED', 'trades_jan.csv', current_timestamp()),
('T003', '1', 'S3', '20240117', '200',  '0.32',    'BUY',  'COMPLETED', 'trades_jan.csv', current_timestamp()),
('T004', '3', 'S4', '20240118', '10',   '210.50-', 'SELL', 'COMPLETED', 'trades_jan.csv', current_timestamp()),
('T005', '4', 'S1', '20240119', '500',  '15.75',   'BUY',  'COMPLETED', 'trades_jan.csv', current_timestamp()),
('T006', '5', 'S2', '20240120', '25',   '',        'SELL', 'PENDING',   'trades_jan.csv', current_timestamp()),
('T007', '9', 'S1', '20240121', '100',  '16.00',   'BUY',  'COMPLETED', 'trades_jan.csv', current_timestamp());

-- Célula 6: Confirmar ingestão
SELECT 'raw_customers'  AS tabela, COUNT(*) AS total FROM bronze.raw_customers
UNION ALL
SELECT 'raw_trades',               COUNT(*) FROM bronze.raw_trades
UNION ALL
SELECT 'raw_securities',           COUNT(*) FROM bronze.raw_securities;
