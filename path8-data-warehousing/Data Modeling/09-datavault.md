# Data Vault 2.0 — In a Nutshell

> **Módulo:** Data Warehousing with Databricks — Path 8  
> **Tema:** Metodologia e arquitectura Data Vault 2.0 — componentes, work-process e mapeamento Lakehouse

---

## Índice

1. [Introdução ao Data Vault 2.0](#1-introdução-ao-data-vault-20)
2. [Componentes Core](#2-componentes-core)
3. [Implementar Hubs](#3-implementar-hubs)
4. [Implementar Links](#4-implementar-links)
5. [Implementar Satellites](#5-implementar-satellites)
6. [Arquitectura em Camadas](#6-arquitectura-em-camadas)
7. [Work-Process: do Lógico ao Físico](#7-work-process-do-lógico-ao-físico)
8. [Mapeamento Data Vault 2.0 ↔ Databricks Bronze/Silver/Gold](#8-mapeamento-data-vault-20--databricks-bronzesilvergold)
9. [Metodologia](#9-metodologia)
10. [Resumo Comparativo](#10-resumo-comparativo)

---

## 1. Introdução ao Data Vault 2.0

**Data Vault 2.0** é uma evolução avançada da metodologia original (DV 1.0), concebida para responder à complexidade do data warehousing moderno. Combina os pontos fortes do DV 1.0 com suporte a big data, analytics em tempo real e práticas de desenvolvimento ágil.

### Objectivos-chave

- **Escalabilidade e flexibilidade** para lidar com ambientes de dados grandes e em rápida mudança.
- **Integração de dados** a partir de fontes diversas com latência mínima.
- **Desenvolvimento ágil e iterativo** para maior velocidade de deployment e capacidade de adaptação.

### Importância

- Responde às exigências das empresas contemporâneas por insights de dados oportunos, precisos e abrangentes.
- Facilita a integração de dados estruturados e não estruturados, acomodando vários tipos e fontes de dados.

> **Frase de referência:** *"Data Vault Modeling was, is, and always will be about the business."* — Dan Linstedt (criador do Data Vault)

---

## 2. Componentes Core

O Data Vault 2.0 assenta em **três tipos de entidade fundamentais**, mais dois componentes adicionais introduzidos na versão 2.0:

| Componente | O que representa | Atributos típicos |
|------------|-----------------|-------------------|
| **Hub** | Entidade de negócio central (chave de negócio única) | Business Key, Load Date, Record Source |
| **Link** | Relação/associação entre Hubs | FKs dos Hubs, Load Date, Record Source |
| **Satellite** | Atributos descritivos e histórico de Hubs ou Links | Campos de dados, Load Date, Record Source, End Date |
| **Pit Table** *(DV 2.0)* | Consolidação ponto-no-tempo de múltiplos Satellites | — |
| **Bridge Table** *(DV 2.0)* | Relações many-to-many complexas e hierarquias | — |

### Regra essencial de design

```
Hub       → "O QUÊ existe" (entidades de negócio)
Link      → "COMO se relacionam" (associações entre entidades)
Satellite → "O QUE sabemos sobre eles" (atributos + histórico)
```

---

## 3. Implementar Hubs

### Propósito

- Representam **chaves de negócio**: pontos centrais de integração para dados relacionados.
- Garantem **consistência e rastreabilidade** das entidades de negócio core.

### Considerações de Design

- **Business Keys:** identificadores estáveis e únicos (e.g., Customer ID, Product SKU). Nunca usar surrogate keys como business key.
- **Atributos mínimos:** manter simplicidade e reduzir redundância — os Hubs *não* guardam atributos descritivos.
- **Ingestion Date e Record Source:** obrigatórios para auditoria e lineage.

### Best Practices

- Convenções de nomenclatura consistentes (e.g., `Hub_Customer`, `Hub_Product`).
- Cada Hub representa **uma única** business key — sem duplicação.
- Manter integridade referencial entre Hubs e os seus Links/Satellites.

### Exemplo de estrutura Hub

```sql
CREATE TABLE Hub_Customer (
    hub_customer_key  BIGINT GENERATED ALWAYS AS IDENTITY, -- Surrogate key interna
    customer_id       STRING NOT NULL,   -- Business Key (chave de negócio)
    load_date         TIMESTAMP,         -- Data de ingestão
    record_source     STRING             -- Origem do registo
);
```

---

## 4. Implementar Links

### Propósito

- Capturam **relações entre Hubs** (e.g., Customer compra Product).
- Permitem modelar relações **many-to-many sem redundância**.

### Considerações de Design

- **Identificar relações:** determinar como as business keys interagem entre si.
- **Foreign Keys:** referenciam as primary keys dos Hubs relacionados.
- **Load Date e Record Source:** registam quando e de onde a relação foi ingerida.

### Best Practices

- **Relações atómicas:** um Link deve representar *uma única* relação entre Hubs.
- Evitar sobrecomplicar: Links destinam-se a relações de negócio com significado real.
- **Escalabilidade:** desenhar para acomodar expansões e novas relações no futuro.

### Exemplo de estrutura Link

```sql
CREATE TABLE Link_CustomerProduct (
    link_customer_product_key  BIGINT GENERATED ALWAYS AS IDENTITY,
    hub_customer_key           BIGINT NOT NULL,   -- FK → Hub_Customer
    hub_product_key            BIGINT NOT NULL,   -- FK → Hub_Product
    load_date                  TIMESTAMP,
    record_source              STRING
);
```

---

## 5. Implementar Satellites

### Propósito

- Armazenam dados **descritivos, contextuais e time-variant** associados a Hubs ou Links.
- Permitem **tracking histórico** e auditoria de alterações ao longo do tempo.
- São o equivalente Data Vault dos atributos SCD — mas de forma mais granular e flexível.

### Considerações de Design

- **Segmentação:** separar Satellites por área temática *ou* por frequência de actualização (e.g., dados demográficos vs. dados transaccionais num Satellite separado).
- **Metadata obrigatória:** `Load_Date`, `Record_Source`, `End_Date`.
- **SCDs:** os Satellites gerem nativamente alterações em atributos de dimensão — cada nova versão é uma nova linha.

### Best Practices

- **Separação granular:** Satellites distintos para tipos de dados diferentes.
- **Mecanismos de actualização uniformes:** processos consistentes para actualizar dados nos Satellites.
- **Documentação:** registar o propósito e conteúdo de cada Satellite.

### Exemplo de estrutura Satellite

```sql
CREATE TABLE Sat_Customer_Demographics (
    sat_customer_demo_key  BIGINT GENERATED ALWAYS AS IDENTITY,
    hub_customer_key       BIGINT NOT NULL,   -- FK → Hub_Customer
    name                   STRING,
    address                STRING,
    market_segment         STRING,
    load_date              TIMESTAMP,         -- Início de validade
    end_date               TIMESTAMP,         -- Fim de validade (NULL = activo)
    record_source          STRING
);
```

---

## 6. Arquitectura em Camadas

### Três camadas físicas

```
┌─────────────────────────────────────────────────────────────┐
│                    RAW DATA VAULT                           │
│  Ingestão dos dados tal como vieram da origem              │
│  Garante integridade e rastreabilidade                     │
│  Componentes: Hubs, Links, Satellites                      │
└─────────────────┬───────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────────────┐
│                 BUSINESS DATA VAULT                         │
│  Enriquece o Raw Vault com lógica de negócio               │
│  Dados derivados e contexto adicional                      │
│  Componentes: Derived Satellites, Calculated Metrics,      │
│               Pit Tables, Bridge Tables, Views             │
└─────────────────┬───────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────────────┐
│             INFORMATION DELIVERY LAYER                      │
│  Fornece dados para consumo final                          │
│  Componentes: Data Marts (Star/Snowflake),                 │
│               APIs, BI Tools, Data Cubes                   │
└─────────────────────────────────────────────────────────────┘
```

### Integração com tecnologias modernas

- **Big Data:** integra nativamente com Hadoop, Spark e cloud data warehouses.
- **Real-Time Processing:** suporta ingestão e streaming analytics em tempo real.
- **Agile/DevOps:** CI/CD para testes automáticos, deployment e version control. Desenvolvimento modular e paralelo de componentes.

---

## 7. Work-Process: do Lógico ao Físico

O processo Data Vault começa **pelo negócio** e vai até ao modelo físico — ao contrário do Kimball que começa pelos requisitos de reporting.

### Modelo Lógico

| Etapa | O que é | Para que serve |
|-------|---------|----------------|
| **Ontology** | Como o negócio vê os seus dados | Modelar entidades reais; conectar conceitos de negócio com business keys; aprofundar hierarquias (Taxonomies) |
| **Taxonomies** | Hierarquia de classificação dos objectos | Estrutura hierárquica; captura propriedades de membership; regras de classificação completas, consistentes e não ambíguas |

### Modelo Físico (ordem de modelação)

```
Information Mart → Business Vault → Raw Vault
(começa-se pelo que o negócio precisa, trabalha-se para trás)
```

> **Nota importante:** A ordem de modelação física é **inversa** à ordem de carga dos dados. Modela-se primeiro o Information Mart (o output) para garantir que o Raw Vault serve as necessidades reais do negócio.

---

## 8. Mapeamento Data Vault 2.0 ↔ Databricks Bronze/Silver/Gold

Este é o slide mais importante para o exame — a ligação entre a metodologia DV 2.0 e a arquitectura Lakehouse do Databricks:

| Camada DV 2.0 | Camada Databricks | O que acontece |
|---------------|-------------------|----------------|
| **Landing** | `bronze` | Dados brutos no formato original (temporário) |
| **Ingestion** | `bronze` *(staging)* | Dados convertidos para Delta (de Avro, CSV, Parquet, XML, JSON); validação do data contract (schema, timeframe) |
| **Integration — Raw Vault** | `silver` | Dados modelados como Hubs (business keys), Links (relações), Satellites (atributos descritivos) |
| **Integration — Business Vault** | `silver` | Regras de negócio aplicadas; data quality; cleansing; conforming. Inclui: Business Views, PIT Tables (opt.), Bridge Tables (opt.) |
| **Presentation — Information Marts** | `gold` | Data Mart clássico com dados limpos e harmonizados; modelos orientados ao consumidor (tipicamente views); acesso via SQL |

### Diagrama de fluxo

```
Sources → Landing (bronze) → Ingestion (bronze)
                                    ↓
                         ┌──────────────────────┐
                         │   silver (Integration)│
                         │  ┌────────┬─────────┐ │
                         │  │  Raw   │Business │ │
                         │  │ Vault  │  Vault  │ │
                         │  │Hub/Link│PIT/Bridge│ │
                         │  │  Sat  │  Views  │ │
                         │  └────────┴─────────┘ │
                         └──────────┬────────────┘
                                    ↓  ETL/ELT
                         ┌──────────────────────┐
                         │    gold (Presentation)│
                         │   Information Mart    │
                         │   Business Views      │
                         │   (consumer SQL)      │
                         └──────────────────────┘
```

---

## 9. Metodologia

O ciclo de vida de um projecto Data Vault 2.0 segue estas fases:

| Fase | Actividades |
|------|-------------|
| **Planning & Requirements** | Definir objectivos de negócio, métricas-chave e fontes de dados; estabelecer governance e padrões de qualidade |
| **Modeling** | Desenhar Hubs, Links e Satellites com base em business keys e relações; incorporar Pit e Bridge Tables conforme necessário |
| **ELT Development** | Desenvolver processos ELT (Extract, Load, Transform) para popular Raw e Business Data Vaults; implementar checks de qualidade e lógica de transformação |
| **Testing & Validation** | Garantir exactidão, integridade e performance; validar contra requisitos de negócio e use cases |
| **Deployment & Maintenance** | Deploy para produção; monitorização contínua, manutenção e melhoria do data warehouse |
| **Agile Practices** | Desenvolvimento iterativo em incrementos gerenciáveis; equipas cross-functional; feedback contínuo para refinar o modelo e os processos ELT |

---

## 10. Resumo Comparativo

### Data Vault 2.0 vs. Kimball (Star Schema)

| Dimensão | Data Vault 2.0 | Kimball (Star Schema) |
|----------|---------------|----------------------|
| **Foco** | Integração e auditoria | Reporting e analytics |
| **Flexibilidade** | Alta — fácil adicionar fontes | Moderada — requer redesign |
| **Histórico** | Nativo em todos os Satellites | Requer SCD nas dimensões |
| **Complexidade** | Maior (mais tabelas) | Menor (mais intuitivo) |
| **Consumo** | Requer Information Marts para BI | Directamente consultável |
| **Melhor para** | Empresas com muitas fontes, auditoria rigorosa | Equipas de BI, self-service analytics |
| **Camada Databricks** | silver (Raw + Business Vault) | gold (DimX + FactX) |

> **Regra prática:** No Databricks Lakehouse, o Data Vault vive maioritariamente na camada **silver** (integração), enquanto o Kimball/Star Schema é a camada **gold** (apresentação). Podem e devem coexistir: o Data Vault serve como staging auditável, e os Information Marts (gold) são construídos a partir dele com um modelo dimensional.
