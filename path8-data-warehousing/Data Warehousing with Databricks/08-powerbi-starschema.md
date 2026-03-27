# Databricks — Power BI Integration & Star Schema
 O ponto mais importante a reter aqui — e que liga tudo o que estudaste até agora — é o resumo final: a camada gold do medallion architecture é o ponto de publicação natural para Power BI. 
 Construíste o pipeline todo (bronze → silver → gold) exatamente para chegar aqui. 

## 1. Power BI Integration

### Overview

A feature **"Publish to Power BI Workspace"** permite criar datasets Power BI diretamente a partir do Databricks, trazendo a performance do Azure Databricks para todos os utilizadores de negócio.

Como aceder: `Catalog Explorer → schema → Publish to Power BI workspace`

> Também disponível a opção de abrir diretamente no Power BI Desktop ou Tableau Desktop.

---

### Requisitos

| Requisito | Detalhe |
|---|---|
| **Fonte de dados** | Unity Catalog apenas — Hive Metastore **não é suportado** |
| **Nível de publicação** | Schema (não é possível publicar tabelas individuais) |
| **Licença Power BI** | Premium (capacity ou per-user) — versão mínima **2.98.683.0** |
| **Private link workspaces** | Requer configuração manual de credenciais em Power BI |
| **Modelo de dados** | Recomendado usar **star schema** |

📖 Mais info: https://learn.microsoft.com/en-us/azure/databricks/partners/bi/power-bi#requirements

---

## 2. Star Schema

### O que é

Técnica de modelação de dados amplamente usada em Data Warehousing e Business Intelligence.  
Consiste em dois tipos de tabelas:

| Tipo | Descrição |
|---|---|
| **Fact table** | Tabela central com dados quantitativos (métricas/medidas) e foreign keys para as dimensões |
| **Dimension table** | Tabelas em redor com atributos descritivos que fornecem contexto às métricas |

---

### Exemplo — Sales

**Fact table: Sales**

| SaleID (PK) | ProductID (FK) | SaleDate | Quantity | TotalAmount |
|---|---|---|---|---|

**Dimension table: Products**

| ProductID (PK) | Name | Category |
|---|---|---|

- `SaleID` é a **primary key** da fact table (surrogate key — inteiro auto-incrementado)
- `ProductID` na tabela Sales é uma **foreign key** que referencia a PK da tabela Products
- Evita duplicar informação de produto em cada linha de venda

---

### Estrutura visual — porquê "estrela"

```
             Products (dim)        Customers (dim)
                  ↑                      ↑
                  |                      |
Products (dim) ←——  Sales (fact)  ——→  Stores (dim)
```

À medida que se adicionam mais dimensões, a estrutura toma a forma de uma estrela com a fact table no centro.

---

### Rationale — porquê usar star schema (especialmente com Power BI)

| Razão | Detalhe |
|---|---|
| **Melhor performance de queries** | Estrutura desnormalizada reduz joins complexos → execução mais rápida |
| **User-friendly** | Layout intuitivo — mais fácil para utilizadores de negócio entenderem e consultarem |
| **Escalabilidade** | Fácil de estender com novas dimensões ou medidas |
| **Otimizado para Power BI** | Funciona bem com o modelo de relações do Power BI, cálculos DAX e funcionalidades de reporting |
| **Standard da indústria** | Alinhado com princípios de Data Warehousing amplamente aceites |

📖 Power BI optimization: https://learn.microsoft.com/en-us/power-bi/guidance/power-bi-optimization  
📖 Power BI Desktop getting started: https://learn.microsoft.com/en-us/power-bi/fundamentals/desktop-getting-started  
📖 Power BI large models: https://learn.microsoft.com/en-us/power-bi/enterprise/service-premium-large-models  
📖 Power BI relationships: https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-relationships-understand  
📖 Star schema guidance: https://learn.microsoft.com/en-us/power-bi/guidance/star-schema

---

## Resumo — Databricks → Power BI

```
Databricks (Unity Catalog)
  └── Schema (gold layer, star schema)
        └── Publish to Power BI Workspace
              └── Power BI Dataset
                    └── Reports & Dashboards
```

A camada **gold** do medallion architecture é o ponto natural de publicação para Power BI — dados já limpos, agregados e modelados em star schema, prontos para consumo por utilizadores de negócio.
