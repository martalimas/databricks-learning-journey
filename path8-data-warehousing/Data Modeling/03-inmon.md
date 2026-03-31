# Estratégias de Modelação de Dados — Parte 3: Inmon em Resumo

> **Módulo:** Data Modeling Strategies  
> **Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner  
> **Âmbito:** Corporate Information Factory de Bill Inmon — abordagem top-down, princípios, arquitectura, ETL, Data Marts e benefícios

---

## Corporate Information Factory de Bill Inmon

Bill Inmon é frequentemente referido como o **"pai do data warehousing"**. A sua Corporate Information Factory (CIF) fornece um framework abrangente para construir Enterprise Data Warehouses (EDWs).

| | |
|---|---|
| **Princípios-chave** | Abordagem top-down, dados integrados, orientação por assunto, variância temporal e não-volatilidade |
| **Importância** | Estabelece uma arquitectura robusta que suporta tomada de decisão estratégica e iniciativas de business intelligence |

---

## Abordagem Top-Down de Data Warehousing

> *Construir a fundação antes dos Data Marts*

Inmon defende a criação de um **data warehouse centralizado** antes de desenvolver data marts especializados.

### Fluxo do Processo

```
Fontes de Dados  →  EDW (fonte única de verdade)  →  Data Marts (por área de negócio)
```

- **Enterprise Data Warehouse (EDW):** serve como a fonte única de verdade
- **Data Marts:** derivados do EDW para servir funções de negócio específicas

### Vantagens

- Garante consistência
- Reduz redundância de dados
- Providencia uma visão unificada em toda a organização

---

## Modelação de Dados Orientada por Assunto

> *Organizar os dados em torno de assuntos de negócio*

Com Inmon, os dados são categorizados por **assuntos** (ex: vendas, finanças, inventário) em vez de por aplicações ou processos.

| | |
|---|---|
| **Benefícios** | Aumenta a clareza e relevância para os utilizadores de negócio; facilita análise e reporting de dados |
| **Implementação** | Utiliza modelos dimensionais como star schemas dentro de cada área de assunto, garantindo que os dados estão organizados logicamente |

---

## Dados Integrados e Consistentes

> *Garantir uniformidade dos dados em todo o warehouse*

**Integração:** combina dados de fontes distintas, garantindo consistência em formatos, convenções de nomenclatura e definições.

### Desafios Resolvidos

- Resolve silos de dados
- Elimina discrepâncias
- Harmoniza diferentes padrões de dados

### Técnicas

| Técnica | Descrição |
|---|---|
| **Processos ETL** | Operações de Extract, Transform, Load — cruciais para a integração de dados |
| **Gestão de Metadados** | Mantém informação sobre fontes de dados, transformações e estruturas para suportar a integração |

---

## Dados com Variância Temporal (Time-Variant)

> *Capturar dados históricos para análise de tendências*

Os data warehouses armazenam dados históricos, permitindo análise ao longo de diferentes períodos de tempo.

### Importância

- Permite às organizações rastrear mudanças, identificar tendências e fazer previsões informadas

### Implementação

| Técnica | O que faz |
|---|---|
| **Snapshot Schemas** | Capturam dados em intervalos específicos |
| **Slowly Changing Dimensions (SCD)** | Gerem alterações nos atributos de dimensão ao longo do tempo sem perder precisão histórica |

> **Ligação ao Databricks:** as SCDs são implementadas no Silver/Gold com Delta Lake — o Time Travel do Delta permite consultar versões históricas de tabelas directamente.

---

## Armazenamento de Dados Não-Volátil (Non-Volatile)

> *Estabilidade e consistência dos dados do warehouse*

Uma vez que os dados entram no data warehouse, **não são actualizados nem eliminados** — permanecem estáveis para garantir fiabilidade.

### Vantagens

- Providencia um registo histórico consistente
- Aumenta a confiabilidade para a tomada de decisão

### Implicações Operacionais

- Foca-se no **carregamento de dados em modo append-only**, prevenindo alterações não intencionais e preservando a integridade dos dados

> **Ligação ao Databricks:** o Delta Lake suporta neste princípio com transacções ACID — os dados podem ser adicionados de forma confiável sem risco de corrupção do histórico.

---

## Arquitectura da Corporate Information Factory

### Componentes Core e os seus Papéis

| Componente | Papel |
|---|---|
| **Enterprise Data Warehouse (EDW)** | Repositório central que integra dados de todas as fontes |
| **Data Marts** | Subconjuntos do EDW, adaptados para áreas de negócio específicas |
| **Operational Data Store (ODS)** | Trata dados transaccionais actuais para reporting operacional |
| **Camada ETL** | Gere a extracção, transformação e carregamento de dados para o warehouse |
| **Repositório de Metadados** | Armazena informação sobre fontes de dados, estruturas e transformações |
| **Ferramentas de Acesso** | Facilitam a recuperação de dados, reporting e análise para os utilizadores finais |

### Diagrama da Arquitectura CIF

```
Fontes Operacionais
  (RDBMS, Ficheiros, Apps)
           │
           ▼
    ┌─────────────┐
    │  Camada ETL  │  ◄── Repositório de Metadados
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │     ODS      │  (dados actuais/transaccionais)
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │     EDW      │  (fonte única de verdade — 3NF)
    └──────┬──────┘
           │
    ┌──────┼──────┐
    ▼      ▼      ▼
  Data   Data   Data    ◄── Ferramentas de Acesso (BI, Reporting)
  Mart   Mart   Mart
 (Vendas)(Fin.) (Inv.)
```

---

## Processos ETL — Extract, Transform, Load

> *A espinha dorsal da integração de dados*

| Fase | O que faz |
|---|---|
| **Extract** | Recupera dados de vários sistemas fonte — bases de dados, aplicações e ficheiros externos |
| **Transform** | Limpa, padroniza e enriquece os dados para garantir consistência e qualidade |
| **Load** | Insere os dados transformados no data warehouse, organizados para consulta e análise eficientes |

### O que o Transform pode envolver

- **Data cleansing** — remoção de duplicados, correcção de erros
- **Data integration** — combinação de dados de diferentes fontes
- **Data transformation** — conversão de tipos de dados, agregação de dados

### Ferramentas e Tecnologias

Exemplos: Informatica, Talend, Microsoft SSIS — automatizam e gerem processos ETL.

> **No Databricks:** o ETL é implementado com Delta Live Tables (DLT) / Lakeflow, PySpark e SQL — substituindo as ferramentas tradicionais com uma solução unificada na plataforma.

---

## Data Marts em Data Warehouses Inmon

> *Subconjuntos especializados para análise dirigida*

Os Data Marts são segmentos focados do data warehouse, desenhados para servir linhas de negócio ou departamentos específicos.

### Tipos de Data Marts

| Tipo | Descrição |
|---|---|
| **Dependente** | Alimentado directamente pelo EDW — garante consistência |
| **Independente** | Criado a partir de fontes de dados separadas — usado tipicamente em abordagens bottom-up, mas pode complementar a estratégia top-down |

### Benefícios

- Desempenho melhorado para consultas específicas
- Modelos de dados adaptados às necessidades únicas de diferentes grupos de utilizadores

### Integração com o EDW

Garante que todos os data marts mantêm alinhamento com o data warehouse centralizado para reporting unificado.

---

## Benefícios da Corporate Information Factory

> *Porquê escolher a abordagem top-down?*

| Benefício | Descrição |
|---|---|
| **Escalabilidade** | Suporta crescimento através de uma arquitectura flexível e expansível |
| **Consistência** | Mantém definições e padrões de dados uniformes em toda a organização |
| **Visão Abrangente** | Oferece uma perspectiva enterprise-wide, facilitando a tomada de decisão holística |
| **Qualidade dos Dados** | Enfatiza processos rigorosos de integração e limpeza de dados |
| **Investimento a Longo Prazo** | Foca-se na construção de uma infraestrutura de dados sustentável e manutenível que se adapta às necessidades de negócio em evolução |

---

## Inmon vs. Medallion Architecture — Mapeamento

| Conceito Inmon | Equivalente no Lakehouse Databricks |
|---|---|
| Fontes operacionais + ETL | **Bronze** — ingestão raw de todas as fontes |
| ODS (dados actuais/limpos) | **Silver** — dados limpos, conformados e enriquecidos |
| EDW (3NF integrado) | **Silver/Gold** — modelo integrado e governado |
| Data Marts | **Gold** — tabelas optimizadas por domínio/caso de uso |
| Repositório de Metadados | **Unity Catalog** — governance centralizada e linhagem |
| Camada ETL | **Lakeflow / DLT / PySpark** |

---

*Notas geradas a partir dos slides do Databricks Learning Festival 2026 — repo: `github.com/martalimas/databricks-learning-journey`*
