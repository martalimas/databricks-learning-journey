# Quiz — SQL Programming and Procedural Logic
**Databricks Learning Festival 2026 · Pathway 8: Data Warehousing Practitioner**

---
# Quiz — SQL Programming and Procedural Logic

**Módulo:** SQL Programming and Procedural Logic  
**Pathway:** 8 — Data Warehousing Practitioner  
**Questões registadas:** 15 de 20

---

## Legenda
- ✅ Resposta correcta
- ❌ Resposta errada (com correção)

---

## Q1 — ITERATE vs LEAVE em SQL Loops

**Pergunta:** What is the key difference between ITERATE and LEAVE statements in SQL loops?

- ~~LEAVE requires a condition while ITERATE does not~~ ❌
- ITERATE is used in WHILE loops while LEAVE is used in FOR loops
- ITERATE exits the loop completely while LEAVE continues to the next iteration
- **LEAVE exits the loop completely while ITERATE skips to the next iteration** ✅

> **Nota:** `LEAVE` = `break` (sai do loop); `ITERATE` = `continue` (salta para a próxima iteração). Nenhum dos dois requer condição por si próprio — são usados dentro de `IF`.

---

## Q2 — Avaliação de ELSEIF

**Pergunta:** In conditional logic with multiple ELSEIF clauses, when does evaluation stop?

- After a predetermined number of evaluations
- **When the first TRUE condition is found** ✅
- After all conditions are evaluated
- When a FALSE condition is found

> **Nota:** Short-circuit evaluation — assim que encontra a primeira condição verdadeira, executa e para. A ordem dos `ELSEIF` importa.

---

## Q3 — Sintaxe para definir uma UDF em SQL

**Pergunta:** Which SQL syntax is used to define a SQL UDF?

- BEGIN FUNCTION
- **CREATE OR REPLACE FUNCTION** ✅
- DECLARE UDF
- DEFINE FUNCTION

---

## Q4 — DECLARE EXIT HANDLER com múltiplos handlers

**Pergunta:** When using DECLARE EXIT HANDLER, what determines which handler executes when multiple handlers are defined?

- The order they are declared in the code
- **The specificity of the condition they handle** ✅
- ~~The first handler that matches the error type~~ ❌
- The alphabetical order of handler names

> **Nota:** Handlers mais específicos (ex: `SQLSTATE '42000'`) têm precedência sobre handlers genéricos (ex: `SQLEXCEPTION`), independentemente da ordem de declaração.

---

## Q5 — Performance do For Each com arrays grandes

**Pergunta:** When using For Each task with large arrays, what is the most important performance consideration?

- Network bandwidth requirements
- Array size limits
- Memory allocation per iteration
- **Concurrency settings to control parallel execution** ✅

> **Nota:** O setting de max concurrency controla quantas iterações correm em simultâneo. Sem controlo, pode sobrecarregar o SQL Warehouse.

---

## Q6 — Parâmetro SQLSTATE no SIGNAL

**Pergunta:** In error handling with SIGNAL statements, what does the SQLSTATE parameter represent?

- **A standardized error code following SQL standards** ✅
- The line number where the error occurred
- The user who triggered the error
- The severity level of the error

> **Nota:** SQLSTATE é um código de 5 caracteres do standard ISO SQL. Ex: `'45000'` = erro definido pelo utilizador; `'42000'` = erro de sintaxe.

---

## Q7 — Tasks downstream quando upstream é skipped

**Pergunta:** In Lakeflow Jobs, what happens to downstream tasks when an upstream task is skipped due to conditional logic?

- **Downstream tasks are automatically skipped** ✅
- Downstream tasks execute with null inputs
- Downstream tasks execute with default values
- ~~The job fails with a dependency error~~ ❌

> **Nota:** No lab, quando o ramo False não foi activado, a Task 5 ficou com estado **"Excluded"** — não falhou. O job terminou como Succeeded.

---

## Q8 — Benefício das CTEs vs lógica repetida

**Pergunta:** Which benefit is gained by using CTEs over repeating query logic?

- Storing row-level business logic
- Granting cross-cloud data access
- **Improving clarity and maintainability** ✅
- Enforcing transaction boundaries

---

## Q9 — Cláusula USING no EXECUTE IMMEDIATE

**Pergunta:** In the EXECUTE IMMEDIATE statement, what is the primary purpose of the USING clause?

- **To pass parameter values safely to the dynamically constructed SQL** ✅
- To define the return type of the dynamic query
- To set the execution timeout for the dynamic query
- ~~To specify the database schema for the dynamic query~~ ❌

> **Nota:** `USING` injeta valores como parâmetros bind, evitando SQL injection e concatenação de strings. Equivalente a `sp_executesql` com `@params` no SQL Server.

---

## Q10 — Comando para atribuir valor a uma variável

**Pergunta:** What command is used to assign a value, either a literal or a query result, to a declared variable?

- **SET** ✅
- INPUT
- UPDATE
- SELECT INTO

---

## Q11 — Sintaxe de LOOP com label

**Pergunta:** What is the correct syntax for a labeled LOOP in Databricks?

- **label_name: LOOP ... END LOOP label_name;** ✅
- LOOP label_name: ... END LOOP;
- label_name LOOP ... END LOOP;
- LOOP ... END LOOP label_name;

---

## Q12 — Scope de variáveis em BEGIN...END

**Pergunta:** In a compound statement (BEGIN...END block), what happens to variables declared within the block?

- They become global variables accessible throughout the session
- They can be accessed by other users in the workspace
- They are automatically persisted to the metastore
- **They are scoped only to that compound statement** ✅

---

## Q13 — Scope das CTEs

**Pergunta:** When using Common Table Expressions (CTEs) in Databricks SQL, which statement about their scope is correct?

- CTEs persist across multiple notebook cells and can be reused
- CTEs can be referenced by other users in the same workspace
- **CTEs are only available within the single query where they are defined** ✅
- CTEs automatically create temporary tables in the default schema

> **Referência de scope:**
> CTE → só dentro da query | Variável → só dentro do BEGIN...END | Temp View → sessão inteira | Tabela → permanente no catálogo

---

## Q14 — Performance de UDF para categorização de valores

**Pergunta:** When creating a SQL UDF that categorizes values, which approach provides the best performance?

- Separate UDFs for each category
- **A single CASE statement with WHEN clauses** ✅
- Multiple nested IF statements
- String manipulation functions

> **Nota:** Um único `CASE` é avaliado numa única passagem pelo motor SQL — mais eficiente e mais legível que `IF` aninhados ou UDFs separadas.

---

## Q15 — SIGNAL sem EXIT HANDLER

**Pergunta:** What happens when a SIGNAL statement is executed without an EXIT HANDLER?

- A default handler is automatically invoked
- ~~The error is converted to a warning~~ ❌
- **The script terminates and returns the error to the caller** ✅
- The error is logged but execution continues

> **Nota:** `SIGNAL` sem handler propaga o erro para cima e termina o script — equivalente a `RAISERROR` no SQL Server sem `TRY...CATCH`.

---

## Resumo de Erros

| Q | Resposta Dada | Resposta Correcta |
|---|---|---|
| Q1 | LEAVE requires a condition | LEAVE exits loop / ITERATE skips to next iteration |
| Q4 | First handler that matches | Specificity of the condition |
| Q7 | Job fails with dependency error | Downstream tasks automatically skipped |
| Q9 | To specify the database schema | To pass parameter values safely (bind params) |
| Q15 | Error is converted to a warning | Script terminates and returns error to caller |

**Score parcial (15 questões):** 10/15 correctas ✅

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
