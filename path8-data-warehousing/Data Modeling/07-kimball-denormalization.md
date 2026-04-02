# Estratégias de Modelação de Dados — Parte 6: Kimball — Desnormalização, Processo e Mapeamento Lakehouse

> **Módulo:** Data Modeling Strategies  
> **Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner  
> **Âmbito:** Desnormalização prós/contras, Databricks e desnormalização, star vs. snowflake visual, processo Kimball, mapeamento Bronze→Silver→Gold

---

## Kimball e Desnormalização

### Desnormalização — Prós e Contras

| | Prós | Contras |
|---|---|---|
| **Performance de queries** | Tabelas pré-joined eliminam joins multi-tabela dispendiosos — queries mais rápidas | — |
| **Intuitividade** | Estrutura star schema alinha-se com a forma como os analistas pensam e reportam dados | — |
| **BI e Agregação** | Medidas e dimensões pré-agregadas — reduz tempo de computação | — |
| **Feature Stores para AI** | Modelos ML precisam frequentemente de tabelas largas e planas — resultado directo da desnormalização | — |
| **Redundância** | — | Fact tables armazenam valores de dimensão repetidos, levando a maiores requisitos de armazenamento |
| **Risco de inconsistência** | — | Actualizações têm de ser cuidadosamente geridas para evitar dados desalinhados em múltiplas tabelas |
| **Actualizações transaccionais** | — | Abordagem Kimball é optimizada para leitura — actualizações transaccionais são complexas |
| **Overhead de armazenamento** | — | Tabelas largas e planas podem resultar em custos de armazenamento mais elevados face a schemas normalizados |

---

## Desnormalização e a Plataforma Databricks

Três pontos-chave sobre como o Databricks lida com desnormalização:

**1. O armazenamento colunar eliminou a penalização da desnormalização**
O Delta Lake (armazenamento colunar) reduziu a necessidade de normalização estrita — ter múltiplas colunas na mesma tabela já não implica o custo de ter de fazer scan a uma linha completa.

**2. A compressão mitiga a duplicação**
A desnormalização quase sempre implica duplicação de dados a algum nível — mas os mecanismos de compressão e filtering do Databricks limitam o impacto real dessa duplicação.

**3. Structs permitem ter o melhor dos dois mundos**
Com a capacidade de armazenar formatos de linha em colunas (structs), o arquitecto de dados pode ter tabelas pré-joined mas com os dados isolados em structs separados — tratados tanto como tabelas individuais como como um resultado pré-joined.

```sql
-- Exemplo: dimensão cliente embebida como struct na fact table
-- Em vez de fazer JOIN, os atributos do cliente ficam dentro da fact table
SELECT
  o.o_orderkey,
  o.o_totalprice,
  o.customer.c_name,        -- acesso directo ao struct
  o.customer.c_mktsegment   -- sem necessidade de JOIN
FROM fact_orders o
```

> **Conclusão:** no Databricks, os argumentos tradicionais contra a desnormalização (custo de armazenamento, performance de scan) perdem força — o que torna o modelo Kimball ainda mais adequado para a camada Gold.

---

## Star Schema vs. Snowflake Schema — Comparação Visual

```
STAR SCHEMA                        SNOWFLAKE SCHEMA
─────────────────────              ──────────────────────────────────
                                   product_category
product ── sales ── customer       product_details ── product ──┐
               │                                                 │
             store                 store_region ─┐    sales ── customer ── customer_country
                                   store_type  ──┘      │                 customer_city
                                                       store              customer_role
```

| | Star Schema | Snowflake Schema |
|---|---|---|
| **Fact table** | Contém factos de negócio (montantes, quantidades) | Igual ao star schema |
| **Dimension tables** | Informação descritiva — tipicamente **desnormalizadas** | Decompostas em **sub-dimensões normalizadas** |
| **Dimensões** | Planas | Normalizadas |
| **Modelo de dados** | Simples, fácil de usar | Mais rigoroso, melhor integridade de dados |
| **Retrieval** | Rápido — menos joins | Mais lento — mais joins |
| **Manutenção** | Baixa | Mais esforço de setup e manutenção |
| **Uso típico** | Gold layer no Databricks | Silver layer quando integridade > performance |

---

## Dimensional Modeling segundo Kimball — Conceitos Fundamentais

> Referência: [Kimball Dimensional Modeling Techniques](https://www.kimballgroup.com/wp-content/uploads/2013/08/2013.09-Kimball-Dimensional-Modeling-Techniques11.pdf)

Os 9 conceitos fundamentais do Kimball:

1. **Recolher Requisitos de Negócio e Realidades dos Dados**
2. **Workshops Colaborativos de Dimensional Modeling**
3. **Processo de Design Dimensional em 4 Passos** ← *o mais importante para o exame*
4. **Business Processes**
5. **Grain**
6. **Dimensions for Descriptive Context**
7. **Facts for Measurements**
8. **Star Schemas and OLAP Cubes**
9. **Grace Extensions to Dimensional Modeling**

---

## O Processo de Design Dimensional em 4 Passos (Kimball)

> *O Design Model de Kimball — aplicado a cada processo de negócio*

```
Processos de Negócio         Passo 1                Passo 2
─────────────────────        ──────────────────     ─────────────────────
Assortment Plans             Para cada BP:          Para cada facto,
Purchase Orders         ──►  definir 1..N Factos ──► definir a granularidade
Inventory                                           mais baixa
Customer Orders
Customer Shipments                │
Credit                            ▼
Returns                    Passo 3                  Passo 4
Trended Surveys            ──────────────────────   ─────────────────────
General Ledger             Para cada facto,    ──►  Para cada facto,
                           definir dimensões        definir todas as
                                                    medidas
```

| Passo | Acção |
|---|---|
| **1 — Seleccionar o Processo de Negócio** | Escolher qual o processo a modelar (ex: Customer Orders) |
| **2 — Determinar a Granularidade** | Definir o que representa uma linha na fact table (o nível mais baixo de detalhe) |
| **3 — Escolher as Dimensões** | Para cada facto, definir quais as dimensões que fornecem contexto |
| **4 — Identificar as Medidas** | Para cada facto, definir todas as métricas/medidas a capturar |

---

## Dimensional Modeling no Lakehouse — Mapeamento Bronze→Silver→Gold

### Visão do Processo Kimball

```
Requisitos de Negócio
    ├── Tech Arch Design ──────────────┐
    ├── Dimensional Modeling ──► Physical Design ──► ETL Design & Development ──► BI Development
    └── BI App Design ────────────────────────────────────────────────────────► BI Development
```

### Mapeamento para as Camadas Medallion

| Camada Medallion | Papel no Kimball | Detalhes |
|---|---|---|
| **Bronze — Landing** | Raw data temporária | Dados raw no formato original (temporariamente) |
| **Bronze — Ingestion** | Staging | Dados raw convertidos para Delta (de Avro, CSV, Parquet, XML, JSON); contrato de schema verificado; também chamado Staging |
| **Silver — Integration** | Physical Data Model (3NF*) | Informação detalhada cobrindo múltiplos domínios de negócio (inclui glossário e taxonomia); integra todas as fontes de dados; **não usa necessariamente um modelo dimensional**, mas alimenta os modelos dimensionais |
| **Gold — Data Mart** | Dimensional Model (Star Schema) | Subconjunto da camada de integração, filtrado ou agregado; foco em dimensional modeling com star schema; tipicamente orientado a uma linha de negócio ou equipa específica |

> *3NF = Third Normal Form em data modelling

### Diagrama completo

```
Bronze                Silver                    Gold
──────────────────    ──────────────────────    ──────────────────────
Landing               Integration               Data Mart
┌──────────────┐      ┌──────────────────────┐  ┌──────────────────┐
│ Raw data     │      │ Business Information │  │   Dim. Model     │◄── SQL
│ (temp.)      │──►   │ Model               │──►│  (Star Schema)   │
└──────────────┘      │                      │  └──────────────────┘
                      │ Logical Data Model   │
Ingestion             │ (3NF*)               │  ┌──────────────────┐
┌──────────────┐      │                      │  │   Dim. Model     │◄── SQL
│ Verified     │──►   │ Physical Data Model  │──►│  (Star Schema)   │
│ data         │      └──────────────────────┘  └──────────────────┘
└──────────────┘
                      ETL/ELT ──────────────►
```

**Dimensional model (star schema) na camada Gold:**
```
         Dim         Fact        Dim
       Customer ──── Order ──── Product
                       │
                      Dim
                      Time
```

---

## Resumo Final Kimball — Para o Exame

| | Kimball |
|---|---|
| Abordagem | Bottom-up |
| Schema | Star (preferido) ou Snowflake |
| Desnormalização | Central — dimensões planas e largas |
| Processo | 4 passos: Processo → Grain → Dimensões → Medidas |
| Silver no Lakehouse | Physical Data Model (3NF) — alimenta o Gold |
| Gold no Lakehouse | Data Marts com star schema desnormalizado |
| Vantagem no Databricks | Armazenamento colunar + compressão eliminam penalizações da desnormalização |
| Structs Delta | Permitem tabelas pré-joined mas com dados isolados por domínio |

---

