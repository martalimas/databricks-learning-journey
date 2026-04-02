# Data Products
**Módulo:** Data Products  
**Tipo:** Lecture — Defining Data Products  

---

## Objectivos

- Introduzir o conceito de "data product" numa abordagem orientada a domínios
- Adoptar uma definição de trabalho para qualquer data product
- Compreender categorias e hierarquias de data products
- Explorar processos e o ciclo de vida típico de um data product
- Mapear estas ideias para as capacidades do Lakehouse (Unity Catalog, camadas medallion)
- Introduzir o conceito de **data contracts**
- Considerar topologias possíveis para gerir um portfólio de data products entre domínios

---

## Porquê Data Products?

### O Problema: A Gestão Tradicional de Dados Falha

**Equipas desconectadas, dados inconsistentes e time-to-value lento.**

- **Plataformas centralizadas** têm dificuldade em escalar a governance entre equipas — as abordagens DWH tradicionais requerem ownership central de IT, criando bottlenecks.
- **Equipas em silos** geram datasets fragmentados — datasets redundantes surgem quando diferentes equipas gerem as suas próprias versões.
- **Baixa confiança nos dados** devido a inconsistências e ownership pouco claro — as unidades de negócio recorrem a fontes não oficiais, levando a reporting desalinhado.
- **IA e ML** exigem novos níveis de disponibilidade e reutilização de dados — os modelos de governance tradicionais não acompanham as necessidades de dados em tempo real para IA.

### A Solução: De Data Assets para Data Products

**De datasets fragmentados para activos geridos e reutilizáveis.**

- Data products aplicam **product thinking** à gestão de dados — os dados são detidos, documentados e versionados como produtos de software.
- Cada data product tem **ownership, governance e SLAs** claros — os domínios são responsáveis pela qualidade, conformidade e evolução.
- Os consumidores de dados (IA, BI, analytics) acedem a **dados padronizados e reutilizáveis** — em vez de duplicar datasets, as equipas reutilizam produtos certificados e governados.
- Acelera **IA, ML e colaboração cross-funcional** — Feature Stores, data marts e APIs em tempo real funcionam como data products governados.

---

## Definindo Data Products

### O Conceito Central

> **Um data product facilita um objectivo final através do uso de dados.**

Para publicar dados como data products, é necessário aplicar **"product thinking"**.

Todo o data product:
- **Tem um owner** e é construído para audiências específicas
- Segue um **ciclo de vida de produto** definido
- É definido e descrito por um **data contract**
- É publicado seguindo um **processo de governance** acordado

---

### Características de Usabilidade *(Usability Characteristics)*

Um data product adere a um conjunto de características de usabilidade:

| Característica | Descrição |
|---|---|
| **Discoverable** | Os utilizadores conseguem explorar a disponibilidade dos dados |
| **Addressable** | Endereço permanente e único para acesso programático |
| **Understandable** | Qual é a semântica? Como é serializado? |
| **Trustworthy and truthful** | Representa correctamente o negócio |
| **Natively accessible** | Disponível no ambiente/ferramenta do utilizador |
| **Interoperable and compensable** | Consistência semântica cross-domain |
| **Valuable on its own** | Fornece insights sem necessitar de dados relacionados |
| **Secure** | Controlo de acesso e privacidade |

### Imperativos *(Imperatives)*

Um data product precisa de ser:

- **Consumption-ready:** Trusted pelos consumidores
- **Kept up to date:** Pelas equipas de engenharia, segundo SLAs acordados
- **Approved for use:** Governado através de data contracts/agreements

---

### Atributos do Conceito de Data Product

O data product organiza-se em torno de **6 atributos**, todos sob a responsabilidade do owner:

```
                    Ownership
                       |
     Discoverability ──┼── Quality & Observability
   (published data     |      (trusted data asset)
       product)    [Data Product]
                       |
       Security ───────┼─── Semantic Consistency
  (org-wide data       |   (compliant with governance)
     governance)       |
                    Privacy
               (potentially anonymized)
                       |
            Responsibility of the owner
```

**Mapeamento para as características de usabilidade:**
- Discoverability → Discoverable, Addressable, Natively accessible
- Quality & Observability → Valuable on its own, Understandable, Trustworthy and truthful
- Semantic Consistency → Interoperable and compensable
- Security → Secure

---

## Categorias de Data Products

Data products são muito mais do que tabelas — têm produtores (P) e consumidores (C) variados.

| Categoria | Data Product | Data Engineer | Data Scientist | ML Engineer | Business Analyst | Business User |
|---|---|---|---|---|---|---|
| **Datasets** | Tabular data (SQL tables, dataframes, facts, dimensions, metrics, KPIs...) | P/C | P/C | C | P/C | — |
| | ML & AI features | P/C | P/C | C | C | — |
| | Streams | P/C | C | — | C | — |
| **Models** | Classical ML & AI | — | P/C | P | — | C |
| | LLM | — | P/C | P | — | C |
| **Consumption Channels** | Queries & Notebooks | P/C | P/C | — | C | C |
| | Dashboards | P/C | P/C | — | P/C | C |
| | Reports | P/C | P/C | — | P/C | C |
| | Alerts | P/C | P/C | — | P/C | C |
| | API (served models) | P/C | P/C | — | C | C |

> **Dois grandes grupos:** *Data Resources* (Datasets + Models) e *Data Services* (Consumption Channels)

---

## Hierarquia de Data Products

Os data products organizam-se em três níveis:

```
Source Systems → Source-aligned DPs → Derived DPs → Consumer-aligned DPs
```

| Nível | Descrição | Exemplos |
|---|---|---|
| **Source-aligned** | Representam os dados como estão no sistema operacional, com transformação mínima; limpos para garantir qualidade; primeiro passo para criar produtos mais valiosos | plm, manufacturing, crm_customers, orders... |
| **Derived** | Criados por processamento e transformação de source-aligned DPs ou outros derived DPs; satisfazem necessidades de utilizadores para decision-making; reutilizáveis noutros derived DPs | products, customers, clickstream... |
| **Consumer-aligned** | Construídos especificamente para os utilizadores finais; dashboards, reports | recommendations, product_popularity... |

### Hierarquia com Ownership

- Os **Source-aligned** DPs vivem nas camadas bronze/silver/gold — pertencem aos **Owners e Domains** dos dados de origem.
- Os **Derived** e **Consumer-aligned** DPs vivem em silver/gold — pertencem a **Owners suportados pelo Hub domain**.

---

## Data Products para Combinar Mundos

Uma organização pode ter domínios que seguem paradigmas diferentes:

- **Domínio A:** Padronizado no paradigma de data products (source-aligned + derived)
- **Domínio B:** Segue paradigma Inmon (Staging → DWH 3NF → Data Marts)
- **Domínio C:** Segue paradigma Kimball (Sources → Data Marts → DWH 3NF)

### Data Products como Fachadas *(Facades)*

Os data products permitem que diferentes paradigmas coexistam e partilhem dados. O mecanismo é a **fachada**: um data product implementado como **view ou materialized view** que expõe dados de qualquer paradigma subjacente de forma semanticamente consistente.

Assim, domínios Inmon e Kimball podem publicar data products (facades) que são consumidos por outros domínios como se fossem nativamente data products.

### Integração no Unity Catalog

A arquitectura de referência usa o **Unity Catalog** como camada de governance central:

- **Lakehouse Federation (LF):** Conecta sistemas externos (ex: DWH legado Inmon)
- **External Tables (ET):** Acede a dados em object storage externo (ex: domínio Kimball)
- **D2D Delta Sharing (DS):** Partilha directa Delta entre sistemas Databricks
- O **Data Integration Domain** é governado pelo Unity Catalog e expõe um **Enterprise Catalog** unificado

---

## Processos e Ciclo de Vida

### Os Cinco Processos Core

| Tipo | Processo | Descrição |
|---|---|---|
| **Domain-specific** | **Data Production** | Criação de data products via Ingestão & ETL ou por diferentes equipas orientadas ao negócio |
| | **Data Publishing** | Passo deliberado para fornecer acesso a um data product a outros consumidores |
| | **Data Consumption** | Uso dos próprios dados e de data products publicados para análise, reporting, ML... |
| **Domain-agnostic** | **Federated Computational Governance** | Garante que o ecossistema de dados adere a regras organizacionais e regulamentação da indústria via standardização. Equilíbrio entre centralização e descentralização: os data products conformam-se a um conjunto partilhado de regras, deixando espaço para decisões autónomas por domínio. |
| | **Platform Operations** | Uma equipa central de plataforma define infraestrutura comum, garantindo regras e políticas transversais. Para evitar bottlenecks, as capacidades necessárias são fornecidas em modo Self-Service. |

---

### Ciclo de Vida Típico

```
Inception → Design → Creation → Publishing → Operation + Governance → Retirement
                                                        ↑
                                              Consumption + Value Creation
                         ←←←←← iterate new version ←←←←←
                ←←←←←←←←←←←← feedback ←←←←←←←←←←←←←←←
```

| Fase | Actividades | Responsáveis |
|---|---|---|
| **Inception** | Definir business outcomes desejados; atribuir owner e recursos; definir métricas de negócio | Business/Consumer |
| **Design** | Criar data contract; criar data product design specification; garantir consistência semântica com outros DPs; | Data steward, Product owner |
| **Creation** | Construir pipelines modulares, features, modelos, dashboards, alertas; testar contra o data contract | Data engineer / Data scientist / Business analyst |
| **Publishing** | Deploy via DataOps ou MLOps; publicar no catálogo; gerir permissões de acesso segundo o data contract | Product owner |
| **Operation + Governance** | Monitorizar métricas, qualidade, uso, permissões; gerir pedidos de compliance; auditar acessos | Data steward, DataOps/MLOps |
| **Retirement** | Deprecar produto; informar consumidores; desligar produção; arquivar assets; limpar recursos | — |

### Mapeamento para o Databricks Lakehouse

| Fase do Ciclo de Vida | Ferramentas Databricks |
|---|---|
| **Design** | Docs repo (data contract + data product spec) |
| **Creation** | DLT, Auto Loader, Structured Streaming (ETL); Databricks SQL, Dashboards (DWH); MLflow, Notebooks, Features, AutoML (Lakehouse AI) |
| **Publishing** | Databricks Workflows, Repos, CI/CD, MLOps/LLMOps (Orchestration); Unity Catalog (Access Control, Data Explorer, Lineage, Marketplace) |
| **Operation + Governance** | Unity Catalog (Auditing, Lineage, Lakehouse Monitoring, System Tables) |
| **Consumption** | Unity Catalog (Discovery, Lineage, Access Control); Dashboards (DWH); MLflow, Notebooks (Lakehouse AI) |

---

## Data Contract

> Um data contract é uma forma formal de alinhar domínios e implementar governance federada.

É fornecido pelo **data producer**, mas desenhado tendo o **consumidor** em mente.

### Componentes do Data Contract

| Componente | Conteúdo |
|---|---|
| **Data description** | Nome, owner, descrição, source systems, atributos seleccionados |
| **Data schema** | Tabelas, colunas, info de anonimização e encriptação, filtros, máscaras |
| **Data quality** | Checks de qualidade aplicados, métricas de qualidade |
| **Data SLAs** | Última actualização, datas de expiração, tempo de retenção, restrições de uso, condições de re-partilha |
| **Security** | Quem tem permissão para usar o data product |
| **Explanatory add-ons** *(opcional)* | Notebook, dashboard, sample code |

### Processo de Governance Baseado em Data Contracts

```
1. Domain 1 propõe data contract → Governance Team
2. Governance Team: Avalia, dá feedback, aprova
3. Contract approval → Domain 1
4. Domain 1 publica → Catalog/Marketplace
5. Domain 2 descobre no catálogo
6. Domain 2 entende o uso (via data contract)
7. Domain 2 usa o data product
```

> **Nota:** **Certified data products** têm o "carimbo" da equipa de Governance (golden data products). Outros data products podem ser publicados sem envolver a equipa de Governance.

---

## Data Products Independentes vs. Certificados

**Equilíbrio entre centralização e descentralização.**

| Tipo | Características |
|---|---|
| **Certified Data Products** | Alta qualidade; semanticamente consistentes; facilmente combinados entre domínios; aprovados pela Governance Team |
| **Independent Data Products** | Alta qualidade; mas sem garantia de que podem ser facilmente combinados; publicados autonomamente pelos domínios |

- A **Governance Team** é constituída por representantes de domínios que acordam regras e políticas para os certified DPs e aprovam os seus data contracts.
- Os **Autonomous Data Domains** podem publicar DPs independentemente se considerarem que os seus dados estão melhor representados dessa forma.

---

## Topologias de Data Products

### As Duas Topologias Base

Quando se estrutura uma arquitectura distribuída onde os domínios são autónomos mas precisam de partilhar dados:

| | **Harmonised** | **Hub-and-Spoke** |
|---|---|---|
| **Estrutura** | Domínios totalmente autónomos + catálogo global central | Hub global central + domínios spoke |
| **Governance** | Cada domínio gere o seu ciclo de vida end-to-end | Mais governance central; equipa central mantém infraestrutura |
| **Discovery** | Catálogo global para descoberta central | Hub para publicação e descoberta de DPs |
| **Risco** | Ineficiente se houver muita semelhança/repetibilidade entre DPs | Equipa central pode tornar-se bottleneck |
| **IT central** | Define o blueprint tecnológico e boas práticas | Pode ser um domínio de dados construindo DPs |

### Recomendação: Mix de Ambas

Há tendência para adoptar Hub & Spoke. Para evitar bottlenecks, a arquitectura e os processos devem:

- Suportar domínios autónomos
- Permitir que domínios não-autónomos amadureçam e se tornem autónomos ao longo do tempo
- Mesmo para domínios autónomos, os dados devem ser **publicados centralmente** para garantir governance consistente e um único ponto de descoberta (catálogo global de dados).

---

## Consistência Semântica

Para aumentar a qualidade dos dados e permitir que os utilizadores trabalhem e combinem datasets, os data products publicados precisam de ser **semanticamente consistentes**:

- **Alinhar data products em:**
  - Contexto
  - Granularidade
  - Terminologia (consistência de naming)
- **Garantir correcção** da lógica de negócio

---

## Resumo Mental

```
Data Product = dado tratado como produto de software
             = tem owner + contract + lifecycle + governance

Hierarquia:   Source-aligned → Derived → Consumer-aligned
              (bronze/silver)   (silver/gold)   (gold)

Topologia:    Harmonised (autónomo) vs. Hub-and-Spoke (centralizado)
              → na prática: mix de ambas

Certificação: Certified DP (aprovado pela Governance) vs. Independent DP (autónomo)

Contrato:     Data description + Schema + Quality + SLAs + Security + (Add-ons)
```

> **Insight-chave:** Data products não são apenas tabelas — são o mecanismo que permite a uma organização escalar a governance sem criar bottlenecks, tratando os dados como activos geridos com o mesmo rigor de um produto de software.
