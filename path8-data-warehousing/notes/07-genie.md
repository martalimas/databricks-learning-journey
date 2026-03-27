# Databricks — AI/BI Genie & Genie Spaces
A tabela Dashboards vs Genie é o que mais vale reter — é exatamente o tipo de distinção que aparece em exames e entrevistas.

## 1. O que é o AI/BI Genie

O **Genie** é um espaço de exploração de dados por **linguagem natural**, localizado no menu SQL da UI do Databricks.

Complementa os Dashboards: enquanto os Dashboards respondem a perguntas previamente definidas, o Genie responde a **perguntas ad-hoc** que não estão cobertas pelos dashboards regulares — sem precisar de um analista de dados.

---

## 2. Genie Spaces

Um **Genie Space** é um espaço associado a um conjunto curado de tabelas do Unity Catalog, onde utilizadores podem "falar" com os dados.

### Para quem serve

- **Utilizadores não-técnicos**: solução no-code para obter insights via linguagem natural
- **Stakeholders**: acesso self-service a dados para perguntas de follow-up, sem depender de um analista

### O que permite fazer

- Fazer perguntas em linguagem natural e obter respostas e visualizações automáticas
- Fazer perguntas de follow-up diretamente (discussão contínua com os dados)
- Avaliar respostas, pedir verificação e dar feedback para refinar o contexto do espaço

---

## 3. Como criar um Genie Space

### Opção 1 — A partir de um Dashboard
No dashboard, acede ao menu `···` → **Open draft Genie space**  
O Genie Space usa automaticamente os mesmos dados e contexto do dashboard.

### Opção 2 — Standalone (fora de um dashboard)
`SQL → Genie → New`

Campos a preencher:
| Campo | Descrição |
|---|---|
| **Title** | Nome do espaço |
| **Description** | Que dados estão disponíveis e que tipo de perguntas os utilizadores podem fazer |
| **Default warehouse** | SQL Warehouse a usar para executar as queries |
| **Tables** | Tabelas do Unity Catalog a incluir (manter o scope o mais pequeno possível) |

> **Boa prática:** limitar o número de tabelas ao mínimo necessário para o caso de uso — melhora a precisão das respostas do Genie.

---

## 4. Dashboards vs Genie — Quando usar cada um

| | AI/BI Dashboards | AI/BI Genie |
|---|---|---|
| **Público** | Técnicos e não-técnicos | Principalmente não-técnicos |
| **Tipo de perguntas** | Predefinidas, com refresh periódico | Ad-hoc, exploração livre |
| **Criação** | Requer design e configuração | Basta ligar tabelas e descrever o contexto |
| **Interação** | Visual estático/interativo | Chat conversacional |
| **Casos de uso** | Relatórios regulares, KPIs | Follow-up questions, exploração pontual |

---

## 5. Resumo — AI/BI no Databricks

```
AI/BI Dashboards
└── Visualizações + queries + datasets num único espaço
└── Draft/Published separados
└── Partilha all-in-one (dados + permissões)
└── AI Assistant integrado para criação de visualizações

AI/BI Genie
└── Genie Spaces ligados a tabelas do Unity Catalog
└── Interface de chat para linguagem natural
└── Pode ser criado standalone ou a partir de um Dashboard
└── Feedback loop para refinar o contexto

IA transversal:
├── AI-Generated Docs       → Unity Catalog
├── Databricks Assistant    → Notebooks, SQL Editor, Dashboards
└── Genie Spaces            → Self-service para utilizadores não-técnicos
```
