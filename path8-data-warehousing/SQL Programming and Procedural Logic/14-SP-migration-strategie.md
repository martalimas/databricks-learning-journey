# Estratégias de Migração de Stored Procedures

**Módulo:** SQL Programming and Procedural Logic  
**Secção:** Procedural Logic in Databricks  
**Pathway:** 8 — Data Warehousing Practitioner  
**Formato:** Apenas lecture (10 min) — sem lab

---

## O Desafio das Stored Procedures

As stored procedures são comuns em plataformas legacy como **Teradata, Oracle e SQL Server** — e provavelmente conheces bem este mundo da tua experiência anterior com T-SQL.

O problema ao migrar para o Databricks não é replicar a estrutura exactamente — é **repensá-la**:

| Característica das Stored Procedures Tradicionais | Impacto |
|---|---|
| Encapsulam control flow, branching e lógica multi-step | Útil, mas torna o código monolítico |
| Frequentemente opacas e difíceis de depurar ou manter | Visibility zero sobre o que corre dentro |
| Específicas do dialecto SQL (T-SQL, PL/SQL) | Difíceis de portar entre plataformas |
| Fortemente acopladas ao ambiente de runtime | Pouca flexibilidade para modernizar |

O objectivo da migração não é fazer "lift and shift" — é **tornar a lógica modular, observável e alinhada com o paradigma Lakehouse**.

---

## Partir para Construir Melhor — Decomposição da Lógica

A abordagem recomendada é **decompor** a stored procedure em passos lógicos isolados, em vez de tentar migrar o bloco monolítico como um todo.

### Princípio Base

> Trata cada operação discreta — filtrar, agregar, verificar um threshold — como um passo autónomo.

### Benefícios da Decomposição

- **Testabilidade:** cada step pode ser testado individualmente.
- **Observabilidade:** visibility total sobre o que corre em cada fase.
- **Reutilização:** tasks modulares podem ser usadas em múltiplos jobs.
- **Orquestração flexível:** via ferramentas nativas do Databricks.
- **Alinhamento com Lakehouse:** fluxos de dados em camadas e modulares (Medallion Architecture).
- **Fundação para tradução:** é o ponto de partida para qualquer estratégia de migração.

Esta abordagem move-nos de **lógica de caixa negra** para **Lakeflow Jobs modulares e governados** que escalam com os dados e as equipas.

---

## Estratégia 1: Lakeflow Jobs como Lógica Orquestrada

Os Lakeflow Jobs são a forma **mais directa e poderosa** de substituir stored procedures tradicionais no Databricks hoje.

### Como Funciona

Cada task num Lakeflow Job encapsula um único pedaço de lógica: uma SQL query, um notebook, ou um script Python. As tasks podem:

- Passar parâmetros umas às outras.
- Seguir lógica condicional (`IF/ELSE`).
- Recuperar de falhas através de retries.
- Expor um grafo de dependências claro e ser monitorizadas centralmente.

### Características Principais

| Capacidade | Equivalente em Stored Procedure |
|---|---|
| Tasks modulares (SQL, notebook, Python) | Blocos procedurais dentro da procedure |
| Dependências de tasks e passagem de parâmetros | Variáveis locais e chamadas entre procedures |
| Branching condicional (`IF/ELSE`) | `IF...ELSE` em T-SQL/PL-SQL |
| Loops (`FOR EACH`) | `WHILE` / `CURSOR` em T-SQL |
| Logging, alerting e lineage integrados | Logging manual dentro da procedure |
| Orchestração de grau de produção | SQL Agent Job ou scheduler externo |

> **Conclusão:** Os Lakeflow Jobs transformam lógica procedural complexa em pipelines de dados modulares e de grau de produção.

---

## Estratégia 2: Notebooks como Unidades de Lógica Modular

Os notebooks Databricks são mais do que um editor de código — são **unidades de lógica executáveis e modulares** que suportam SQL, markdown e outputs visuais numa única interface.

### O que os Notebooks Oferecem

- Suporte para execução de lógica SQL multi-step.
- Cada célula actua como um passo procedural — mimicando blocos de stored procedure.
- Combinam comandos SQL, markdown de documentação e resultados numa só interface.
- Úteis tanto para desenvolvimento exploratório como para lógica de grau de produção.
- Suportam versionamento, comentários e colaboração de equipa.
- Podem ser executados interactivamente ou orquestrados em Lakeflow Jobs.

### Notebooks vs. Ficheiros SQL Planos

| Característica | Notebook | Ficheiro .sql |
|---|---|---|
| Execução por passos estruturada | ✓ | ✗ |
| Documentação markdown com código | ✓ | ✗ |
| Preview de resultados e visualizações inline | ✓ | ✗ |
| Fácil de depurar, versionar e anotar | ✓ | Limitado |
| Integração nativa com Lakeflow Jobs | ✓ | ✓ |
| Misturar SQL com Python se necessário | ✓ | ✗ |

---

## Parametrização em Notebooks

Os notebooks parametrizados levam a lógica modular um passo mais além — permitem que o **mesmo script SQL responda dinamicamente a inputs**.

### Como Aceitar Parâmetros

Os notebooks podem receber parâmetros através de:
- **SQL widgets** (`CREATE WIDGET`) — para uso interactivo.
- **Lakeflow Job Task inputs** — para uso em orquestração automatizada.

### Casos de Uso Comuns

- Executar o mesmo notebook para cada departamento, região ou intervalo de datas.
- Ajustar a lógica dinamicamente (ex: threshold de filtro).
- Os parâmetros controlam a lógica SQL **sem reescrever código**.
- O Lakeflow suporta execução em loop com diferentes valores de parâmetros (`FOR EACH`).

> **Analogia:** Em vez de 12 stored procedures — uma por mês —, tens um notebook parametrizado com `:mes` que o Lakeflow executa 12 vezes com valores diferentes.

---

## Estratégia 3: Padrões de Execução Orientados por Metadados

Os frameworks orientados por metadados permitem passar de **lógica hardcoded** para **padrões de execução generalizados**.

### Princípio

Em vez de escrever uma query separada para cada departamento ou tabela, crias uma **tabela de controlo** e deixas essa tabela conduzir a execução dinamicamente.

```
Tabela de Controlo (config)
    │
    ├── entidade: "orders", filtro: "priority=URGENT", datas: ...
    ├── entidade: "returns", filtro: "status=PENDING", datas: ...
    └── entidade: "inventory", ...
    │
    ▼
Lakeflow Job lê a tabela e executa a lógica para cada linha
```

### Benefícios

- Reduz redundância e aumenta a manutenibilidade.
- Aumenta a transparência (o que corre está definido em dados, não em código).
- Alinha com os princípios ELT em arquitecturas Lakehouse modernas.

### Suporte no Databricks

| Ferramenta | Como Suporta Metadados |
|---|---|
| **Spark Declarative Pipelines (SDP)** | Pipelines declarativas, SQL-nativas; conduzidas por regras, não por scripts |
| **dbt** | Framework de transformação modular com macros conduzidos por configuração |

Ideal para Lakeflow Jobs multi-entidade e multi-fase.

---

## Spark Declarative Pipelines (SDP) em Lakeflow Jobs

Os SDP — também conhecidos como Lakeflow Spark Declarative Pipelines — são desenhados para **pipelines declarativas**.

### Como Funciona

Usando sintaxe SQL standard, defines cada fase da transformação com `CREATE LIVE TABLE` (ou `MATERIALIZED VIEW` / `STREAMING TABLE`), e o Databricks gere automaticamente:
- Dependências entre tasks.
- Retries.
- Gestão de metadados.

### Características

- Suporta modos batch e streaming.
- Inclui cláusulas `EXPECT` para data quality enforcement auditável.
- Lógica SQL de scripting inclui: lógica condicional (`WHERE`, `CASE`, joins).
- Integração nativa com SQL Warehouses e Unity Catalog.
- Ideal para pipelines que seguem regras consistentes por tabela ou entidade.

---

## SDP Sozinho vs. SDP + Jobs

Como decidir quando usar SDP puro e quando adicionar orquestração com Lakeflow Jobs?

| Cenário | Usa... |
|---|---|
| Lógica totalmente declarativa, sequência linear, falhas retried ao nível de tabela | **SDP sozinho** |
| Jobs multi-step que requerem branching, condicionais ou iteração | **SDP + Jobs** |
| Necessitas de alerting, passagem de parâmetros ou coordenação de scheduling | **SDP + Jobs** |
| Os pipelines são uma fase dentro de um DAG de orquestração maior | **SDP + Jobs** |

### O que os Lakeflow Jobs Podem Fazer com SDP

- Chamar Pipelines como tasks.
- Encadear Pipelines com scripts SQL ou notebooks.
- Fornecer observabilidade e controlo em runtime.

> **Metáfora:** Pensa no SDP como o **motor de transformação** — e nos Lakeflow Jobs como a **torre de controlo** que coordena múltiplas peças em movimento.

---

## Ferramentas de Automação da Migração

Para organizações com dezenas ou centenas de stored procedures, as ferramentas de automação podem ajudar a **arrancar o processo de migração**.

### Exemplo: BladeBridge

| O que faz | Limitações |
|---|---|
| Analisa e faz parse de stored procedures legacy | O output é um ponto de partida — requer validação e refactoring |
| Gera DAGs de tasks, notebooks candidatos ou workflow stubs | Não elimina a necessidade de redesenho arquitectural |
| Identifica constructs procedurais (branching, SQL dinâmico) | Reduz esforço manual mas não substitui o pensamento estratégico |

> **Princípio:** A automação acelera, mas não substitui o julgamento estratégico necessário para desenhar Lakeflow Jobs modernos.

---

## Escolher a Estratégia Certa

Não existe uma abordagem única para migrar stored procedures. A escolha depende de vários factores:

### Factores a Considerar

| Factor | Impacto na Escolha |
|---|---|
| **Complexidade da lógica e branching** | Mais complexo → Lakeflow Jobs com If/Else |
| **Requisitos de manutenibilidade e reutilização** | Alta reutilização → notebooks parametrizados ou metadados |
| **Skills da equipa** (SQL, Python, dbt, Lakeflow) | Condiciona qual a ferramenta mais adoptável |
| **Necessidades de observabilidade e auditoria** | Alta rastreabilidade → Unity Catalog + lineage |

### Regra Geral

As estratégias combinam-se. A migração raramente usa apenas uma abordagem:

```
Lógica simples e declarativa     → SDP (Pipelines)
Lógica com branching/condicionais → Lakeflow Jobs
Lógica repetitiva multi-entidade  → Metadados + dbt ou SDP
Volume elevado de procedures      → Ferramenta de automação (BladeBridge) + revisão
```

> **Mensagem-chave:** A migração é uma **oportunidade de modernizar, não apenas de re-plataformar**. O objectivo não é replicar a stored procedure — é construir algo melhor.

---

## Resumo

| Estratégia | Quando Usar | Ferramenta Databricks |
|---|---|---|
| **Lakeflow Jobs como lógica orquestrada** | Lógica multi-step com branching, condicionais, retries | Lakeflow Jobs (SQL tasks, If/Else, For Each) |
| **Notebooks como unidades modulares** | Desenvolvimento iterativo, lógica documentada, colaboração | Databricks Notebooks |
| **Notebooks parametrizados** | Mesma lógica para múltiplas entidades/períodos | Notebooks + widgets ou job parameters |
| **Execução orientada por metadados** | Muitas entidades, regras consistentes, lógica dinâmica | SDP (Pipelines) ou dbt |
| **SDP + Jobs** | Pipelines declarativas dentro de orquestração maior | SDP como task dentro de Lakeflow Job |
| **Automação da migração** | Volume elevado de procedures a migrar | BladeBridge ou ferramentas similares |

> A **melhor estratégia é normalmente uma combinação** — orquestração com Lakeflow Jobs, lógica modular em notebooks, e metadados a conduzir a execução onde faz sentido.

Tens agora os três ficheiros completos para a secção Procedural Logic in Databricks:
FicheiroConteúdointroduction_to_lakeflow_jobs.mdLecture teórica — o quê, porquê, componentes, DAG, control flow, scheduling, lineagelakeflow_jobs_demo_lab.mdDemo + lab prático — os 5 steps com SQL, configuração da UI, monitorizaçãostored_procedure_migration_strategies.mdLecture — como migrar stored procedures: decomposição, Lakeflow Jobs, notebooks, metadados, SDP, BladeBridge
