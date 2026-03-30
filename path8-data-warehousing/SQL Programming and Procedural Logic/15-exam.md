# Quiz — SQL Programming and Procedural Logic
**Databricks Learning Festival 2026 · Pathway 8: Data Warehousing Practitioner**

---

> **Nota:** As questões 1–13 foram respondidas em sessão anterior com imagens que não ficaram preservadas em texto. Preenche com as tuas respostas quando tiveres acesso ao quiz novamente.  
> As questões 14–15 foram parcialmente recuperadas do histórico. As questões 16–20 estão completamente documentadas.

---

## Questões 1–13

> ⚠️ _Conteúdo não recuperável — preencher manualmente._

| Q | Pergunta | Resposta Correcta | Resultado |
|---|----------|-------------------|-----------|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |
| 6 | | | |
| 7 | | | |
| 8 | | | |
| 9 | | | |
| 10 | | | |
| 11 | | | |
| 12 | | | |
| 13 | | | |

---

## Questão 14 — UDFs: Best approach for categorization logic ✅

**Pergunta:** What is the most efficient approach when implementing categorization logic in a UDF?

**Opções:**
- Create separate UDFs for each category
- Use a single `CASE` statement ✅
- Use nested `IF` statements
- Use string manipulation

**Resposta correcta: Use a single `CASE` statement**

**Explicação:**  
Um único `CASE` é avaliado numa única passagem pelo motor SQL — é mais performático, mais legível e mais fácil de manter do que `IF` aninhados ou múltiplas funções separadas.

```sql
CREATE OR REPLACE FUNCTION categorize_order(priority STRING)
RETURNS STRING
RETURN CASE priority
    WHEN '1-URGENT' THEN 'Alta Prioridade'
    WHEN '2-HIGH'   THEN 'Prioridade Média-Alta'
    WHEN '3-MEDIUM' THEN 'Prioridade Média'
    ELSE                 'Baixa Prioridade'
END;
```

---

## Questão 15 — SIGNAL without EXIT HANDLER ❌ → ✅

**Pergunta:** What happens when a `SIGNAL` statement is executed in a SQL script without an `EXIT HANDLER` defined?

**Opções:**
- The error is logged silently
- The signal is converted to a warning
- **The script terminates and returns the error to the caller** ✅
- Execution continues from the next statement

**Resposta dada:** _The signal is converted to a warning_ ❌  
**Resposta correcta: The script terminates and returns the error to the caller**

**Explicação:**  
`SIGNAL` lança um erro deliberadamente. Sem um `DECLARE EXIT HANDLER` para o apanhar, o erro propaga-se para cima e o script termina — é equivalente a um `RAISERROR` sem `TRY...CATCH` no SQL Server.

```sql
BEGIN
    -- Sem EXIT HANDLER definido
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro de validação';

    -- Esta linha NUNCA executa
    SELECT 'continuou...';
END;
-- O erro sobe para o caller — script termina com a mensagem definida
```

| Situação | Comportamento |
|---|---|
| `SIGNAL` + `EXIT HANDLER` presente | Handler apanha o erro, execução continua controlada |
| `SIGNAL` sem handler | Script termina, erro devolvido ao caller |

---

## Questão 16 — DECLARE: what is required besides the variable name ❌ → ✅

**Pergunta:** When declaring a variable, what is required besides the variable name?

**Opções:**
- A permanent storage location
- A default value
- A Delta Lake version number
- **An explicit data type** ✅

**Resposta dada:** _A default value_ ❌  
**Resposta correcta: An explicit data type**

**Explicação:**  
A sintaxe completa no Databricks SQL Scripting é:

```sql
DECLARE [OR REPLACE] var_name [datatype] [{ DEFAULT | = } default_expr]
```

Tanto `datatype` como `DEFAULT` são tecnicamente opcionais no Databricks (se omitires o tipo, é inferido do `DEFAULT`), mas para fins do quiz a resposta esperada é **o tipo de dados** — que é o que a maioria dos contextos SQL procedural (T-SQL, PL/SQL) exige.

```sql
DECLARE total_sales INT DEFAULT 0;        -- com tipo explícito ✅
DECLARE total_sales DEFAULT 0;            -- tipo inferido como INT
DECLARE counter INT;                      -- tipo sem default
```

---

## Questão 17 — Variable scope in compound statements ✅

**Pergunta:** Variables declared inside a compound statement adhere to what principle?

**Opções:**
- Global visibility
- **Local scope, only persisting in the block** ✅
- Persisting after execution
- Cross-workspace synchronization

**Resposta correcta: Local scope, only persisting in the block**

**Explicação:**  
Variáveis declaradas dentro de um `BEGIN...END` vivem e morrem com esse bloco — **block-level scoping**.

```sql
BEGIN
    DECLARE x INT DEFAULT 10;  -- x só existe aqui dentro
    SELECT x;                  -- ✅ funciona
END;

SELECT x;  -- ❌ erro: x não existe fora do bloco
```

---

## Questão 18 — Translating Oracle/Teradata to Databricks ✅

**Pergunta:** When translating SQL code from Oracle or Teradata to Databricks, what is a recommended first step?

**Opções:**
- Ignore schema references
- **Identify vendor-specific syntax that needs refactoring** ✅
- Convert all code to Python
- Run the code directly in Databricks

**Resposta correcta: Identify vendor-specific syntax that needs refactoring**

**Explicação:**  
Antes de migrar, é preciso auditar o código para encontrar incompatibilidades:

| Vendor | Exemplos de sintaxe específica |
|---|---|
| Oracle | `ROWNUM`, `CONNECT BY`, `NVL`, packages PL/SQL |
| Teradata | `SEL`, `BTEQ`, `QUALIFY`, `TOP n` |
| Databricks | ANSI SQL + Delta-specific extensions |

---

## Questão 19 — TEMP VIEW vs GLOBAL TEMP VIEW ✅

**Pergunta:** What is the difference between a `TEMP VIEW` and a `GLOBAL TEMP VIEW`?

**Opções:**
- Global views are persistent; temporary views are discarded
- Temporary views are shared across clusters; global views are not
- **Temporary view scope is session-based; global view scope is workspace-based** ✅
- Global views allow DML operations; temporary views do not

**Resposta correcta: Temporary view scope is session-based; global view scope is workspace-based**

**Explicação:**

| | TEMP VIEW | GLOBAL TEMP VIEW |
|---|---|---|
| **Scope** | Sessão atual | Workspace (todas as sessões) |
| **Visível a outros?** | ❌ Não | ✅ Sim |
| **Criação** | `CREATE TEMP VIEW` | `CREATE GLOBAL TEMP VIEW` |
| **Namespace** | Schema corrente | `global_temp` |
| **Duração** | Termina com a sessão | Termina com o cluster |

```sql
-- Temp view — só nesta sessão
CREATE TEMP VIEW vendas_q1 AS SELECT ...;

-- Global temp view — partilhada no workspace
CREATE GLOBAL TEMP VIEW vendas_q1 AS SELECT ...;
SELECT * FROM global_temp.vendas_q1;
```

---

## Questão 20 — SQL widget parameter reference syntax ✅

**Pergunta:** In SQL widget parameter references, what is the correct syntax to reference a widget named `year_filter`?

**Opções:**
- **`:year_filter`** ✅
- `#year_filter`
- `@year_filter`
- `${year_filter}`

**Resposta correcta: `:year_filter`**

**Explicação:**

| Sintaxe | Contexto |
|---|---|
| `:year_filter` | ✅ SQL queries e SQL warehouses (Databricks SQL) |
| `${year_filter}` | Notebooks (células SQL legacy) |
| `#year_filter` | ❌ Não existe no Databricks |
| `@year_filter` | ❌ Não existe no Databricks |

```sql
-- Uso correto em Databricks SQL
SELECT *
FROM sales
WHERE year = :year_filter
  AND region = :region_filter;
```

O prefixo `:` é a sintaxe **ANSI-style named parameter** usada no Databricks SQL para referenciar widgets e parâmetros em queries.

---

_Módulo: SQL Programming and Procedural Logic · Pathway 8: Data Warehousing Practitioner · Databricks Learning Festival 2026_
