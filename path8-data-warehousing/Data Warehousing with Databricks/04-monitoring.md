# Databricks — Monitoring: Tagging & System Tables

## 1. Tagging

### Conceito

Uma **tag** é um par chave/valor atribuído a um recurso do Databricks.  
Tagging = atribuir uma ou mais tags a um recurso.

### Para que serve

| Caso de uso | Descrição |
|---|---|
| **Cost tracking** | Monitorizar e decompor custos por departamento ou projeto |
| **Resource management** | Categorizar e organizar recursos para melhor visibilidade |
| **Policy enforcement** | Integrar com políticas de orçamento e controlos de gastos |
| **Automation** | Permitir que scripts identifiquem e giram recursos programaticamente |

### Onde aplicar

Tags podem ser atribuídas a **SQL Warehouses** (e outros recursos) a qualquer momento — ao criar ou ao editar, via UI ou programaticamente.  
Na UI: `New SQL Warehouse → Advanced Options → Tags`

### Boas práticas

- Standardizar o esquema de chaves/valores em toda a organização
- Usar chaves que atribuam uso a uma **business unit** ou **projeto**
- Adicionar tags mais específicas conforme necessário (role, produto, cliente)
- Enforçar tagging através de workspace ou cloud policies

**Exemplo de tags bem definidas:**

| Key | Value |
|---|---|
| `business-unit` | `finance` |
| `project` | `annual-budget` |
| `customer` | `Acme Anvils LLC` |

**Tags comuns recomendadas:** `project`, `owner`, `department`, `cost-center`

---

## 2. System Tables

### Conceito

System Tables são uma feature do Databricks que expõe **dados operacionais da plataforma** para observabilidade histórica e analytics avançado.  
São governadas e acedidas como qualquer outro objeto de dados — via Unity Catalog.

### Para que serve

- Debugging
- Auditoria
- Controlo de custos
- Eficiência operacional
- Qualidade dos dados

### Estrutura

```
Metastore
  └── system                        ← catálogo especial, auto-provisionado
        ├── access                  → audit logs, lineage, permissões
        ├── billing                 → custos e DBUs consumidos
        └── information_schema      → metadados de todos os objetos no metastore
              ├── tables
              ├── table_privileges
              └── schema_privileges
```

#### Schema: `access`
Audit logs com eventos de: ações de utilizadores, acesso a recursos, alterações de permissões, data lineage.

#### Schema: `billing`
Tracking detalhado de todas as actividades faturáveis — para monitorização de custos, budgeting e reporting.

#### Schema: `information_schema`
Metadados sobre todos os objetos em todos os catálogos do metastore.

### Acesso via SQL

Como são entidades relacionais normais, o acesso é direto via SQL:

```sql
-- Listar todas as tabelas de um owner
SELECT *
FROM system.information_schema.tables
WHERE table_owner = :owner
```

---

## 3. Exemplos práticos com System Tables

### Quem tem acesso a uma tabela?

Combina `table_privileges`, `tables` e `schema_privileges` para identificar quem pode aceder a uma tabela (por ownership ou privilégios explícitos):

```sql
SELECT DISTINCT(grantee) AS `ACCESSIBLE BY`
    FROM system.information_schema.table_privileges
    WHERE table_catalog = :catalog_name
      AND table_schema  = :schema_name
      AND table_name    = :table_name
UNION
    SELECT table_owner
    FROM system.information_schema.tables
    WHERE table_catalog = 'david_leblanc'
      AND table_schema  = :schema_name
      AND table_name    = :table_name
UNION
    SELECT DISTINCT(grantee)
    FROM system.information_schema.schema_privileges
    WHERE catalog_name = :catalog_name
      AND schema_name  = :schema_name
```

---

### Quais jobs consumiram mais DBUs?

```sql
SELECT
  usage_metadata.job_id AS `Job ID`,
  SUM(usage_quantity)   AS `Usage`
FROM system.billing.usage
WHERE usage_metadata.job_id IS NOT NULL
GROUP BY `Job ID`
ORDER BY `Usage` DESC
```

---

### Atribuição de custos por tag (resource attribution)

Combina tagging com system tables para decompor custos por equipa, use case ou business unit:

```sql
SELECT
  sku_name,
  usage_unit,
  SUM(usage_quantity) AS `Usage`
FROM system.billing.usage
WHERE custom_tags[:key] = :value
GROUP BY 1, 2
```

> **Nota:** `custom_tags` é a coluna de `system.billing.usage` que armazena as tags definidas nos recursos — a ponte entre tagging e cost tracking.

---

## 4. Usage Dashboards

Account admins podem gerar **dashboards de custos automáticos** a partir da consola:  
`Account Console → Usage → Setup dashboard`

- Aproveitam os **AI/BI Dashboards** do Databricks (solução low-code)
- Permitem visualizar breakdowns de custos por tag, workspace, SKU, período
- Podem ser filtrados, customizados e partilhados

---

## Ligação entre Tagging e System Tables

As tags definidas nos recursos aparecem na coluna `custom_tags` de `system.billing.usage`.  
Isto permite fazer **chargeback** preciso: atribuir custos reais a equipas, projetos ou clientes com uma simples query SQL.
