# Estratégias de Modelação de Dados — Parte 4: Inmon — Processo de Trabalho e Normalização

> **Módulo:** Data Modeling Strategies  
> **Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner  
> **Âmbito:** Processo de modelação Inmon, normalização UNF→3NF, prós/contras, impacto no Databricks, visualização CIF

---

## Processo de Trabalho de Modelação de Dados (Inmon)

> *Este é um processo iterativo e contínuo ao longo do ciclo de vida do warehouse — informação capturada em passos posteriores pode informar passos anteriores.*

O processo divide-se em duas grandes fases: **Lógica** e **Física**.

### Fase Lógica — 3 etapas

```
┌─────────────────────┐     ┌──────────────────────┐     ┌─────────────────────────┐
│  1. Business        │     │  2. User Views        │     │  3. Composite Logical   │
│  Information Model  │────►│  (Domain)             │────►│  Data Model             │
│  (vista conceptual) │     │  (uma por função)     │     │  (integração e          │
│                     │     │                       │     │   resolução conflitos)  │
└─────────────────────┘     └──────────────────────┘     └─────────────────────────┘
  Perspectiva ampla           Perspectiva por requisito      Integração de dados
  de negócio                  de dados por função/user
```

**1 — Business Information Model (BIM)**
- Modelo de alto nível dos actores e interacções de interesse para o negócio
- Foco em capturar os principais processos de interesse

**2 — User Views (Domain)** *(User = Função de Negócio)*
- Cada processo de negócio é trabalhado individualmente
- Tarefas:
  - Identificar entidades principais
  - Determinar relações entre entidades
  - Determinar chaves primárias e alternadas
  - Determinar chaves estrangeiras
  - Determinar regras de negócio chave
  - Adicionar os atributos restantes
  - Validar regras de normalização
  - Determinar tipos de dados

**3 — Composite Logical Data Model**
- Combina as User Views
- Integra com modelos de dados existentes
- Analisa estabilidade e crescimento

### Fase Física

**4 — Physical Data Model (PDM)** — *Eficiência e usabilidade*
- Traduzir a estrutura lógica de dados
- Identificar tabelas e colunas
- Adaptar a estrutura à tecnologia
- Definir como enforçar regras de negócio em torno das entidades (PK, FK)
- Definir como enforçar integridade (relações)
- Afinar mecanismos de armazenamento

---

## Inmon e Normalização

O EDW de Inmon usa **modelação relacional com dados normalizados (3NF)** como núcleo do data warehouse. Os Data Marts são frequentemente modelos dimensionais ou desnormalizados derivados do EDW.

---

## Normalização: De UNF a 3NF

> *Melhorar a integridade dos dados através de restrições progressivas*

### Unnormalized Form (UNF)
- Os dados podem conter grupos repetidos e atributos multi-valor
- Sem regras impostas sobre a organização dos dados

**Exemplo UNF — tabela de encomendas:**
```
encomenda_id │ cliente    │ produtos
─────────────┼────────────┼──────────────────────────────
1001         │ Marta Lima │ Livro Python, Teclado, Rato
1002         │ João Silva │ Monitor
```
O campo `produtos` tem múltiplos valores — não está normalizado.

---

### 1NF — Primeira Forma Normal
- **Eliminar Grupos Repetidos:** cada campo contém apenas valores atómicos
- **Linhas Únicas:** cada registo deve ser único

**Exemplo 1NF:**
```
encomenda_id │ cliente    │ produto
─────────────┼────────────┼─────────────
1001         │ Marta Lima │ Livro Python
1001         │ Marta Lima │ Teclado
1001         │ Marta Lima │ Rato
1002         │ João Silva │ Monitor
```
Cada linha tem um único produto — mas há redundância no nome do cliente.

---

### 2NF — Segunda Forma Normal
- Já está em 1NF
- **Eliminar Dependências Parciais:** atributos não-chave devem depender inteiramente da chave primária, não apenas de parte dela

**O problema:** a chave primária desta tabela é `(encomenda_id, produto)`. Mas `cliente` depende apenas de `encomenda_id` — dependência parcial.

**Solução 2NF — separar em duas tabelas:**
```
tabela_encomendas          tabela_linhas_encomenda
─────────────────          ───────────────────────
encomenda_id │ cliente     encomenda_id │ produto
─────────────┼──────────   ─────────────┼─────────────
1001         │ Marta Lima  1001         │ Livro Python
1002         │ João Silva  1001         │ Teclado
                           1001         │ Rato
                           1002         │ Monitor
```

---

### 3NF — Terceira Forma Normal
- Já está em 2NF
- **Eliminar Dependências Transitivas:** atributos não-chave devem depender apenas da chave primária — não de outros atributos não-chave

**O problema:** se a tabela de encomendas tiver `cliente_id`, `nome_cliente` e `cidade_cliente` — `cidade_cliente` depende de `nome_cliente`, não directamente de `encomenda_id`.

**Solução 3NF — separar o cliente:**
```
tabela_encomendas          tabela_clientes
─────────────────          ───────────────────────────
encomenda_id │ cliente_id  cliente_id │ nome       │ cidade
─────────────┼──────────   ───────────┼────────────┼────────
1001         │ 1           1          │ Marta Lima │ Lisboa
1002         │ 2           2          │ João Silva │ Porto
```

> **Resumo das três formas:**
> - **1NF** → sem grupos repetidos, valores atómicos
> - **2NF** → sem dependências parciais da chave primária
> - **3NF** → sem dependências transitivas entre atributos não-chave

---

## Normalização — Prós e Contras no Inmon

| | Prós | Contras |
|---|---|---|
| **Redundância** | Minimiza redundância de dados — fonte única de verdade sem duplicação | — |
| **Integridade** | Actualizações ocorrem num único sítio, evitando problemas de sincronização | — |
| **Transacções** | Optimizado para actualizações transaccionais — reduz custos de armazenamento | — |
| **Integração** | Permite modelação cross-enterprise com relações de entidades estritas | — |
| **Desempenho de queries** | — | Estruturas altamente normalizadas requerem múltiplos joins, aumentando a complexidade das queries |
| **Analytics** | — | Joins complexos podem impactar o desempenho de BI e reporting |
| **ETL adicional** | — | Os Data Marts precisam frequentemente de transformação adicional para queries eficientes dos utilizadores finais |
| **AI/ML** | — | Pipelines ML requerem frequentemente feature stores desnormalizadas, exigindo passos de processamento adicionais |

---

## Normalização e a Plataforma Databricks

O motor paralelo do Databricks (**Apache Spark**) é extremamente bom a fazer scan e processar grandes volumes de dados — estes passos podem ser feitos em paralelo por N workers.

**O problema dos joins em Spark:**
Os joins implicam maioritariamente troca de dados entre workers através de serialização e desserialização — o chamado **shuffle** — que é caro em termos de performance.

**Como o Databricks mitiga o impacto da normalização:**

| Funcionalidade | O que faz |
|---|---|
| **Liquid Clustering** | Organiza fisicamente os dados para minimizar o número de ficheiros lidos nas queries |
| **Predictive Optimization** | Optimiza automaticamente tabelas Delta com base nos padrões de utilização |
| **Deletion Vectors** | Torna operações de delete/update eficientes sem reescrever ficheiros inteiros |
| **Gathering of Statistics** | Recolhe estatísticas sobre os dados para o optimizador de queries tomar melhores decisões |

> **Conclusão:** a normalização penaliza performance em sistemas tradicionais. No Databricks, estas funcionalidades modernas reduzem dramaticamente esse impacto — tornando o modelo Inmon mais viável na plataforma.

---

## Inmon Visualizado — Corporate Information Factory

### Visão do Processo e Lógica

```
Requisitos de Negócio
         │
         ▼
Business Information Model
         │
    ┌────┴────────────────┐
    ▼                     ▼
DWH Logical          Data Marts Logical
Data Model           Data Model (LDM)
    │                     │
    ▼                     ▼
DWH Physical         Data Mart
Data Model           (dimensional)
(relacional)
    │                     │
    └────────┬────────────┘
             │
Fontes ──► Staging
             │
             ▼
          DWH (3NF)  ──►  Data Mart  ──►  Data Cube  ──►  👤
                     ──►  Data Mart              ──────►  👤
```

**Dois conceitos-chave desta visualização:**

- O **EDW (DWH 3NF)** é o núcleo — modelação relacional normalizada, integrado a partir do Staging
- Os **Data Marts** são frequentemente dimensionais ou desnormalizados — são derivados do EDW para servir utilizadores finais de forma eficiente

> Esta é a tensão central do Inmon: o EDW é normalizado (bom para integridade), mas os utilizadores finais precisam de modelos desnormalizados (bons para performance de queries) — daí a necessidade dos Data Marts como camada intermédia.

---

## Resumo do Inmon — Pontos-chave para o Exame

| Conceito | Detalhe |
|---|---|
| Abordagem | **Top-down** — EDW primeiro, Data Marts depois |
| Modelo core | **3NF** — normalizado, sem redundância |
| Processo | BIM → User Views → Composite LDM → PDM |
| Vantagens | Consistência, integridade, fonte única de verdade |
| Desvantagens | Joins complexos, mais lento para analytics, ETL pesado |
| Data Marts | Derivados do EDW, frequentemente dimensionais/desnormalizados |
| No Databricks | Silver ≈ EDW (3NF); Gold ≈ Data Marts; Liquid Clustering mitiga joins |

---

*Notas geradas a partir dos slides do Databricks Learning Festival 2026 — repo: `github.com/martalimas/databricks-learning-journey`*
