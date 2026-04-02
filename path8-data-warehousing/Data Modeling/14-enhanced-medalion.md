# O Medallion Melhorado — Enhanced Medallion
**Módulo:** Modern Data Architecture Use Cases — Lecture  
**Tema:** Combining Approaches → The Enhanced Medallion  

---

## O Medallion como Best Practice Pipeline

O Medallion standard é a pipeline de referência no Databricks Lakehouse, com três camadas:

| Camada | Papel | Características |
|---|---|---|
| **Bronze** | Ingestão | Raw data, sem processamento; dados mantidos para corrigir erros |
| **Silver** | Curado | Dados limpos e conformados; directamente queryáveis; PII masking/redaction |
| **Gold** | Final | Tabelas business-level; específicas por projecto/use case; modelos desnormalizados e optimizados para leitura |

A transição de Bronze para Silver utiliza **Spark Streaming**, garantindo processamento incremental dos dados.

A camada Gold pode conter sub-tipos de output: time series resampleadas e interpoladas, feature reduction, e features enriquecidas — típico de use cases de ML.

---

## Combinando Mundos — o Enhanced Medallion

O **Enhanced Medallion** expande o modelo base para acomodar simultaneamente dois mundos distintos dentro do mesmo Lakehouse:

```
batch ──────┐
            ▼
         [Bronze]
streaming ──┤    Landing   →  Curation   →  Final          ← Modern use cases
            └──  Ingestion →  Integration→  Presentation   ← BI use cases
                   (cloud storage)
```

### Subcamadas Detalhadas

#### Bronze — Duas sub-camadas
| Sub-camada | Descrição |
|---|---|
| **Landing (Staging)** | Raw data no formato original; temporário |
| **Ingestion** | Raw data verificado e convertido para **Delta** |

#### Silver — Duas sub-camadas
| Sub-camada | Descrição |
|---|---|
| **Curation** | Dados limpos, homogeneizados e com lógica de negócio fundamental aplicada |
| **Integration** | Business information model — Enterprise DWH (um ou mais) |

#### Gold — Duas sub-camadas
| Sub-camada | Descrição |
|---|---|
| **Final** | Datasets prontos para o negócio/projecto (modern use cases) |
| **Presentation** | Informação DWH pronta para o negócio — **data marts** (BI use cases) |

---

### Os Dois Mundos em Paralelo

```
Silver (Curation)  →  Gold (Final)        → Modern use cases (exploratório, ML, DS)
Silver (Integration) → Gold (Presentation) → BI use cases (dados rigorosamente modelados e verificados)
```

**Combinar ambos os mundos no Lakehouse permite:**
1. **Acesso a KPIs corporativos** para modern use cases
2. **Entrega acelerada** para BI use cases

---

## Três Camadas de Dados para Informação

O Enhanced Medallion organiza-se em dois eixos de leitura:

### Eixo Vertical: Exploratório ↔ Conformado

```
↑ Explorative & Flexible   →  Curation / Final (modern use cases)
↓ Conformed & Stable       →  Integration / Presentation (DWH / BI)
```

### As Três Camadas de Output (Gold)

#### 1. Modern Use Cases (self-service, exploratório)
- **Alta flexibilidade** — suporta todo o tipo de workloads (ML, workloads experimentais)
- Suporta todos os tipos de dados
- **Não requer conformidade** com o business information model

#### 2. Semantically Consistent Data (perspectiva de negócio enriquecida, self-service)
- Não está integrado no business information model formal
- Mas é **transformado de forma consistente** para permitir joins com os dados de integração
- Permite enriquecer perspectivas de negócio **sem desestabilizar o modelo DWH**

#### 3. BI e Advanced Analytics (Presentation — Data Marts)
- Modelo de informação de negócio **estável**, alinhado com objectivos de negócio e OKRs
- Usado para **reporting financeiro, KPIs, dashboards corporativos**
- Segue um **processo de mudança rigoroso**

---

### Mapeamento para Produtos de Dados

| Output | Tipo de Produto de Dados |
|---|---|
| Modern use cases (ML, self-service) | **Arbitrary data & Independent data products** |
| Enhanced business perspective (self-service) | **Certified Data Products** |
| Presentation / Data Marts | **DWH model** |

---

## Resumo Mental — Como Memorizar

```
Bronze  = "recebo tudo tal como vem"
Silver  = "limpo e modelo para o negócio"
Gold    = "sirvo para quem precisa — analistas, cientistas, dashboards"

Enhanced Medallion = Bronze + Silver duplo + Gold duplo
                   = Data Lake moderno  +  DWH clássico
                   = tudo no mesmo Lakehouse
```

> **Insight-chave:** O Enhanced Medallion não substitui nem o modelo dimensional (Kimball) nem o Data Vault — **integra-os** numa arquitectura unificada, onde cada camada serve o seu propósito sem conflito.
