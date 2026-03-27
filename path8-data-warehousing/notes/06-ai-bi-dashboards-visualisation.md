# Databricks — AI/BI Dashboards & Visualização
O ponto-chave deste módulo é perceber a distinção entre os dois produtos: os Dashboards são para construir e partilhar visualizações, enquanto o Genie é para utilizadores não-técnicos explorarem dados por linguagem natural.
O Databricks Assistant é o fio condutor de IA que aparece nos dois

## 1. AI integrado na experiência do utilizador

O Databricks infundiu IA em vários pontos da plataforma para melhorar a descoberta de dados e a produtividade:

| Feature | O que faz |
|---|---|
| **AI-Generated Docs** | Documentação automática de assets no Unity Catalog — facilita pesquisa e descoberta |
| **Databricks Assistant** | Copiloto para notebooks: gera, otimiza, completa, explica e corrige código e queries |
| **AI Assistant para visualizações** | No dashboard, usa linguagem natural para criar ou editar gráficos automaticamente |
| **AI/BI Genie Spaces** | Permite que utilizadores não-técnicos explorem dados com perguntas em linguagem natural |

---

## 2. AI/BI Offerings — Onde estão na UI

Localizadas no menu de navegação sob o header **SQL**:

```
SQL
├── SQL Editor
├── Queries
├── Dashboards      ← AI/BI Dashboards
├── Genie           ← AI/BI Genie
├── Alerts
├── Query History
└── SQL Warehouses
```

---

## 3. AI/BI Dashboards

### O que é

Ambiente **all-in-one** de visualização e apresentação de dados, integrado na plataforma Databricks.  
É a ferramenta principal para apresentar e partilhar resultados analíticos e de BI de forma interativa.

### Características principais

- **Datasets + queries + visualizações** tudo no mesmo espaço
- Interface **drag-and-drop** simples — acessível a utilizadores técnicos e não-técnicos
- **Partilha all-in-one**: permissões de dados, queries e dashboard geridas num único lugar
- **Draft vs Published**: podes continuar a melhorar o dashboard em draft sem perturbar quem já o está a usar
- **Linguagem natural**: usa o Databricks Assistant para criar ou editar visualizações por instrução textual
- Partilhável com qualquer pessoa na organização, independentemente de ter acesso direto ao workspace

### Fluxo de criação

```
1. Adicionar dataset
   └── Escrever SQL próprio ou selecionar tabela existente

2. Adicionar visualização ou filtro ao canvas
   └── Drag-and-drop de widgets (gráfico, filtro, text box)

3. Publicar e partilhar
   └── Permissões geridas automaticamente
```

---

## 4. AI/BI Genie

Permite que **data practitioners** disponibilizem um espaço de exploração de dados assistido por IA à sua base de utilizadores não-técnicos.

- Os utilizadores fazem perguntas em **linguagem natural**
- O Genie interpreta e responde com dados e visualizações relevantes
- Reduz a dependência de analistas para queries ad-hoc

---

## Resumo — AI/BI no Databricks

```
Databricks AI/BI
├── Dashboards      → apresentação, partilha, visualização (técnicos e não-técnicos)
└── Genie Spaces    → exploração self-service via linguagem natural (não-técnicos)

IA transversal à plataforma:
├── AI-Generated Docs   → descoberta de assets no Unity Catalog
└── Databricks Assistant → copiloto em notebooks, SQL Editor e Dashboards
```
