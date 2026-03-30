# Estratégias de Modelação de Dados — Parte 1: Fundação Lakehouse

> **Módulo:** Data Modeling Strategies  
> **Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner  
> **Âmbito:** Introdução + Recap da Arquitectura Lakehouse (slides de fundação antes de Inmon/Kimball/Data Vault)

---

## Objectivos

No final deste módulo deverás ser capaz de:

- Compreender a abordagem **top-down (3NF) de Bill Inmon**
- Mapear os **conceitos EDW de Inmon** para as camadas medallion do Databricks
- Resumir a abordagem **bottom-up e star schema de Kimball** (factos/dimensões)
- Ilustrar como os **star schemas se integram com o Lakehouse**
- Compreender os **Hubs, Links e Satellites do Data Vault 2.0** para evolução ágil de esquemas
- Comparar **Data Vault com Inmon/Kimball**

---

## Mapa de Conteúdos

```
Corporate Information        Dimensional Modeling       Data Vault 2.0
Factory de Inmon         →   de Kimball             →
─────────────────────        ──────────────────────     ──────────────────────
Visão geral da               Facto vs. Dimensão;         Hubs (chaves de negócio),
metodologia Inmon;           Dimensões conformadas,      Links (relações),
Pontos fortes                tipos SCD; Kimball vs.      Satellites (atributos);
(governance, fonte           alinhamento medallion;      exemplo TPC-H;
única de verdade)            Surrogate keys e            Pontos fortes
vs. limitações               criação de dimensões;       (historização, cargas
                             Fact table a referenciar    incrementais)
                             chaves de dimensão          vs. complexidade
```

---

## Recap da Arquitectura Lakehouse

> *Este módulo baseia-se na compreensão dos princípios Lakehouse — todas as decisões de modelação são moldadas por este framework.*

| Princípio | O que significa para a modelação de dados |
|---|---|
| Decisões de modelação dependem das camadas de governance, processamento e armazenamento | A Arquitectura Medallion (Bronze → Silver → Gold) dita **onde** e **como** os dados são transformados |
| O Unity Catalog garante governance e interoperabilidade | Consistência de esquemas, rastreio de linhagem e controlo de acesso impactam como modelamos dados entre domínios |
| Ponte entre AI e BI | Os modelos de dados têm de servir **tanto** analytics estruturado (BI) como feature engineering (AI/ML) |

---

## Princípios Core e Arquitectura Medallion

### O Lakehouse combina Data Lakes e Data Warehouses

- Elimina silos ao suportar dados **estruturados e não estruturados** numa única plataforma.

### Arquitectura Medallion (Bronze → Silver → Gold)

| Camada | Papel | Características principais |
|---|---|---|
| **Bronze** | Ingestão raw | Sem processamento; dados preservados para corrigir erros; registo histórico |
| **Silver** | Curada / Limpa | Dados limpos, conformados e enriquecidos; directamente consultável; mascaramento de PII |
| **Gold** | Final / Optimizada | Desnormalizada, optimizada para leitura; específica por projecto/caso de uso; suporta BI, ML e analytics |

> **Fluxo:** Bronze → *(Spark stream)* → Silver → Gold  
> O Gold pode ramificar em: séries temporais resampled / redução de features / features melhoradas

### Enforcement de Esquemas e Governance

- Suporta formatos abertos como o **Delta Lake** enquanto garante consistência de esquemas.

### Desempenho e Escala

- Combina **transacções ACID**, indexação e cache para consultas de alto desempenho.

---

## Plataforma Moderna de Dados e AI — Visão Geral

```
┌─────────────────────────────────────────────────────────────┐
│  Ferramentas ETL & DS        │  Ferramentas BI              │
├─────────────────────────────────────────────────────────────┤
│                     Orquestração                            │
├────────────────────┬──────────────────────┬─────────────────┤
│  Ingest & Transform│ Analytics Avançado,  │  Data Warehouse │
│                    │ ML & AI              │                 │
├────────────────────┴──────────────────────┴─────────────────┤
│                       Motor de AI                           │
├─────────────────────────────────────────────────────────────┤
│                  Governance de Dados & AI                   │
├─────────────────────────────────────────────────────────────┤
│                     Armazenamento Cloud                     │
└─────────────────────────────────────────────────────────────┘
```

Personas servidas: **Data Engineer · ML Engineer · Data Scientist · Business Analyst · Business Partners**

---

## Unity Catalog para Governance e Modelação

> *O Unity Catalog é a espinha dorsal de governance que torna possível uma modelação de dados consistente em todo o Lakehouse.*

| Capacidade | Detalhe |
|---|---|
| **Governance Centralizada** | Gere esquemas, tabelas e permissões em todos os workspaces e clouds |
| **Enforcement de Esquemas e Linhagem** | Rastreia movimentos de dados, transformações e dependências para reprodutibilidade de modelos |
| **Controlo de Acesso Granular** | Permissões ao nível de coluna e linha — dados seguros mas acessíveis |
| **Interoperabilidade entre Domínios** | Definições consistentes entre equipas; evita **schema drift** |
| **Multi-Cloud e Formatos Abertos** | Acesso governado a Delta Lake, Parquet e outros formatos |

### Antes vs. Depois do Unity Catalog

**Antes:** Cada workspace tinha o seu próprio User/group management, Metastore, Access controls e Compute resources de forma isolada.

**Depois (Com Unity Catalog):** Uma única camada Unity Catalog (User/group management + Metastore + Access controls) é partilhada por todos os workspaces; cada workspace mantém os seus próprios Compute resources.

### Hierarquia de Objectos do Unity Catalog

```
Conta Databricks
  └── (Unity) Metastore
        └── Catalog
              └── Schema
                    ├── Table
                    ├── View
                    ├── Volume
                    ├── Function
                    └── Model
```

**Convenção de nomenclatura com três partes:**
```sql
SELECT * FROM catalog1.schema1.table1;
```

---

## Data Intelligence e Feature Engineering

> *Um Lakehouse bem modelado serve simultaneamente BI e AI.*

| Conceito | Ponto-chave |
|---|---|
| **Lakehouse suporta BI e AI** | SQL analytics, dashboards BI e feature engineering por AI coexistem numa arquitectura unificada |
| **Feature Engineering precisa de pipelines escaláveis** | Cargas de trabalho AI precisam de processamento em tempo real **e** batch para extracção e transformação de features |
| **Feature Stores** | Previnem "training-serving skew" ao armazenar **features reutilizáveis e versionadas** entre pipelines ML |
| **Data Intelligence** | Combina modelação preditiva com analytics histórico para insights mais profundos |
| **Inferência em Tempo Real e Batch** | Modelos ML aproveitam dados de streaming + históricos para decisões precisas em tempo real |

---

## Mosaic AI — Capacidades de AI End-to-End

A camada de AI do Databricks chama-se **Mosaic AI** e está totalmente integrada na Plataforma de Data Intelligence.

### Blocos de capacidade de alto nível

| Bloco | O que faz |
|---|---|
| **MLOps + LLMOps** | Move código, dados e modelos entre desenvolvimento e produção; gere modelos, features e experiências |
| **Preparação de Dados** | Descobre e transforma dados estruturados em features; cria embeddings de dados não estruturados |
| **Desenvolver e Avaliar AI** | Treina/testa algoritmos; fine-tuning e prompt engineering; cria agentes GenAI; avalia experiências |
| **Servir Dados e AI** | Serving de modelos e features com baixa latência; regista pedidos/respostas; consulta embeddings em Vector DB |
| **Motor de AI** | Descoberta e pesquisa por AI, AI Assistant, optimização de desempenho e escala |
| **Governance de Dados e AI** | Segurança e permissões; linhagem de modelos; monitorização de dados e AI (métricas, qualidade, drift) |

### Ferramentas Específicas do Mosaic AI

| Área | Ferramentas |
|---|---|
| MLOps / LLMOps | MLflow, Asset Bundles (CI/CD) |
| Desenvolver e Avaliar | AutoML, AI Playground, Model Training, Agent Framework, Agent Evaluation |
| Servir Apps | AI Gateway, Model Serving, AI Functions, Databricks Apps |
| Servir Dados | Function Serving, Feature Serving, Vector Search |
| Governance | Model Registry no UC, Feature Store no UC, Tools Catalog no UC, Models no Marketplace |
| Integrações externas | HuggingFace, OpenAI, LangChain, … |

---

## Conclusões Principais

| Conclusão | Porquê é importante |
|---|---|
| O Lakehouse integra dados estruturados e não estruturados | Suporta BI, ML e analytics em tempo real num único framework |
| A Arquitectura Medallion providencia um fluxo de dados estruturado | Bronze (raw) → Silver (limpo) → Gold (optimizado) define onde e como os modelos de dados são aplicados |
| O Unity Catalog garante governance e consistência | Esquemas padronizados, controlo de acesso e rastreio de linhagem permitem modelação confiável |
| As Feature Stores fazem a ponte entre AI e analytics de negócio | Garante definições de features consistentes e versionadas entre workflows de treino e inferência |
| Uma estratégia forte de modelação baseia-se nestes princípios | Os dados mantêm-se escaláveis, governados e optimizados para AI e analytics |

---

## O Que Vem A Seguir

1. **Corporate Information Factory de Inmon** — top-down, 3NF, EDW → mapeado para camadas medallion  
2. **Dimensional Modeling de Kimball** — bottom-up, star schemas, factos e dimensões → integrado com o Lakehouse  
3. **Data Vault 2.0** — Hubs / Links / Satellites, evolução ágil de esquemas → exemplo de mapeamento TPC-H  

---

*Notas geradas a partir dos slides do Databricks Learning Festival 2026 — repo: `github.com/martalimas/databricks-learning-journey`*
