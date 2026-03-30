# Estratégias de Modelação de Dados — Parte 2: Porquê Modelar + Fundamentos DWH

> **Módulo:** Data Modeling Strategies  
> **Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner  
> **Âmbito:** Fundamentos de modelação DWH, visão geral de metodologias, conceitos de modelação lógica, processo de construção de DWH

---

## Porquê Modelar? — Modelação de Dados em DWH

Um data warehouse é utilizado por **utilizadores de negócio** para avaliar e tomar decisões empresariais.  
Os dados do data warehouse precisam de ser modelados para:

- Representar correctamente **o negócio**
- Garantir que os insights e decisões baseados no data warehouse sejam **impactantes**

### Como?

| Passo | O que envolve |
|---|---|
| Compreender o negócio | Os seus actores, relações, processos e requisitos |
| Criar um modelo lógico de dados | Modelo formal dos processos e necessidades de negócio da organização |
| Garantir qualidade dos dados | Precisos, consistentes e bem organizados |
| Suportar BI eficazmente | Analytics, reporting e business intelligence |

**Fluxo de modelação:**

```
Modelo de Negócio       →   Modelo Lógico         →   Implementação DWH     →   BI, Analytics
(processos, actores,        (modelo formal de          (específico de             e Reporting
 relações,                   negócio, agnóstico         tecnologia)
 requisitos)                 em termos de tecnologia)
```

---

## Metodologias de Modelação de Dados — Três Escolas de Pensamento

Historicamente, três metodologias dominantes para practitioners de data warehousing:

| Metodologia | Autor | Livro | Ano |
|---|---|---|---|
| **Abordagem top-down** | Bill Inmon | *Building the Data Warehouse* | 1992 |
| **Abordagem bottom-up** | Ralph Kimball | *The Data Warehouse Toolkit* | 1996 |
| **Data Vault 2.0** | Dan Linstedt | *Building a Scalable Data Warehouse with Data Vault 2.0* | 2015 |

---

## Data Warehousing — Propósito da Modelação

```
                        Requisitos de Negócio
                          (Necessidade de Informação)
                                 │
              ┌──────────────────┼──────────────────────┐
              │   Ambiente Data Warehouse                │
              │                                          │
              │   ┌──────────────────────────────────┐  │
              │   │   Modelo de Informação de Negócio │  │
              │   └───────┬─────────────────┬─────────┘  │
              │           │                 │             │
              │   ┌───────▼──────┐  ┌───────▼──────┐    │
              │   │ Modelo Lógico│  │ Modelo Lógico│    │
              │   │  DWH (LDM)   │  │ Data Mart    │    │
              │   └───────┬──────┘  └──────┬───────┘    │
              │           │                │             │
Fontes ──►   │   ┌───────▼──────┐  ┌──────▼───────┐   │  ──► Apps
(RDBMS,      │   │  Modelo Físico  │  │  Data Mart   │   │  ──► Ferramentas BI
 Ficheiros,  │   │  de Staging  │  │              │   │
 Apps,       │   └──────────────┘  └──────────────┘   │
 Clouds)     └───────────────────────────────────────────┘
             Fonte   Ingestão  Integração  Entrega/Acesso
```

---

## Contexto para os Conceitos

> A abordagem Inmon fornece uma **base conceptual agnóstica em termos de metodologia** para a modelação de dados.

Conceitos-chave com origem no Inmon — como o **modelo lógico** — traduzem-se eficazmente para as terminologias das metodologias concorrentes (ontologias e taxonomias usadas no Kimball e Data Vault).

Ou seja: aprende o vocabulário Inmon uma vez, aplica em todo o lado.

---

## Modelação Lógica de Dados — Termos-Chave

| Termo | Definição |
|---|---|
| **Entidade** | Pessoa, lugar, coisa ou conceito sobre o qual se pretende registar factos |
| **Atributo** | Peça de informação atómica e não decomponível que descreve uma entidade |
| **Não-Decomponível** | A menor unidade de informação à qual se vai querer fazer referência |
| **Regras de Negócio** | Especificações que preservam a integridade do LDM, governando os valores que os atributos podem assumir |

### Regras de Negócio — Duas Categorias

- **Regras de negócio de chave** — a identificação de registos únicos
- **Regras de negócio de domínio** — validação dos valores dos atributos

---

## Modelação Lógica de Dados — Abordagem Óptima

Um bom modelo lógico de dados deve satisfazer seis qualidades:

| # | Qualidade | Definição |
|---|---|---|
| 1 | **Validade estrutural** | Consistência com a forma como o negócio define e organiza a informação |
| 2 | **Simplicidade** | Facilidade de compreensão |
| 3 | **Sem redundância** | Sem informação desnecessária |
| 4 | **Partilhabilidade** | Não específico a uma solução — utilizável por muitos |
| 5 | **Extensibilidade** | Capacidade de evoluir com impacto mínimo na base existente |
| 6 | **Integridade** | Consistência com a forma como o negócio utiliza e gere os valores de informação |

---

## Construir um DWH — O Processo

Os modelos são **centrais** quando se constrói um data warehouse. Três tipos de modelos:

| Modelo | Definição |
|---|---|
| **Business Information Model (BIM)** | Modela actores, as suas relações e como interagem — "como o negócio funciona" |
| **Logical Data Model (LDM)** | Modelo dos dados associados ao BIM |
| **Physical Data Model (PDM)** | O modelo de dados implementado, derivado do LDM |

Os modelos **descrevem o mundo do negócio** e as suas relações — retratam os processos de negócio dentro da organização, e geram o contexto necessário para criar informação significativa a partir dos dados.

### Processo DWH Simplificado

```
ANALISAR                    DESENHAR                      CONSTRUIR
──────────────────          ──────────────────────        ──────────────────────
Requisitos de negócio  ──►  Design de Staging        ──►  Dados de Fonte em Staging

Business Information
Model
        │
        ▼
Modelo Lógico de       ──►  Modelação Física de      ──►  Implementação DWH
Dados                        Dados

Modelo Lógico de
Data Mart              ──►  Modelação Física de
                             Data Mart

Análise de Dados de Fonte

Mapeamento de Fontes   ──►  Design ETL              ──►  Desenvolvimento ETL
                                                           ▲
                                                    (alimenta de volta para
                                                     Implementação DWH)
```

### As Três Fases Explicadas

| Fase | Características |
|---|---|
| **Analisar** | Agnóstico em termos de tecnologia — compreensão pura do negócio |
| **Desenhar** | Impactado pela tecnologia e pela compreensibilidade para os consumidores |
| **Construir** | Usa a tecnologia real para implementar o modelo físico e os processos ETL |

---

## Data Warehousing no Lakehouse

Quando se migra ou implementa um DWH, o arquitecto de dados tipicamente **não está em posição de ditar** as metodologias legadas que o negócio usa.

**A vantagem do Databricks:**

- O Lakehouse pode facilmente suportar a **coexistência harmoniosa** de tantas metodologias DWH legadas quantas o negócio necessite (Inmon + Kimball + Data Vault podem todos coexistir)
- Um Lakehouse bem arquitectado **abre novas oportunidades** para aplicar dados de data warehouse a casos de uso modernos (ML, analytics em tempo real, AI)

> Insight-chave: Não precisas de escolher uma metodologia e abandonar as restantes. O Lakehouse é suficientemente flexível para as hospedar todas em simultâneo.

---

*Notas geradas a partir dos slides do Databricks Learning Festival 2026 — repo: `github.com/martalimas/databricks-learning-journey`*
