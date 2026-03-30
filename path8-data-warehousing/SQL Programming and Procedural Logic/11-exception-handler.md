# SQL Scripting in Databricks — Error and Exception Handling

> **Pathway 8 · SQL Programming and Procedural Logic**  
> Tópico: Error and Exception Handling + Workflow-Ready Scripting

---

## O problema por defeito

Sem tratamento de erros, um script Databricks SQL **falha imediatamente** quando encontra um erro em runtime — e para. Para workflows complexos (pipelines, validações, ETL), isto não é aceitável. É aqui que entram os **handlers** e os **signals**.

---

## Conceitos fundamentais

| Conceito | O que faz |
|---|---|
| `DECLARE EXIT HANDLER FOR <condição>` | Define um bloco de lógica que corre quando um erro específico ocorre. `EXIT` significa que o bloco principal termina após o handler executar. |
| `SQLEXCEPTION` | Categoria genérica que apanha qualquer erro SQL em runtime |
| `SIGNAL SQLSTATE '...' SET MESSAGE_TEXT = '...'` | Lança um erro explicitamente — podes definir o código e a mensagem |
| `SQLSTATE` | Código de 5 caracteres que identifica o tipo de erro (ex: `'45000'` = erro genérico definido pelo utilizador) |

> **Regra:** Tudo o que é tratamento de erros tem de viver dentro de um `BEGIN...END`.  
> O handler é declarado **antes** da lógica que pode falhar — tal como variáveis.

---

## Fluxo de execução com handler

```
Script entra no BEGIN
    ↓
Handler é registado (mas não executa ainda)
    ↓
Lógica principal corre...
    ↓
    ├── Sem erro → execução normal até END
    └── Erro ocorre → controlo salta para o handler
                          ↓
                     Handler executa
                          ↓
                     (EXIT) script termina
```

---

## Exemplo completo — divide-by-zero com fallback

```sql
BEGIN

    -- 1. Declarar variável para guardar o resultado
    DECLARE sales_total DOUBLE;

    -- 2. Declarar o handler ANTES da lógica que pode falhar
    --    FOR SQLEXCEPTION = apanha qualquer erro SQL em runtime
    --    EXIT = após o handler executar, o bloco principal termina
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Lógica de fallback: lança um erro com mensagem legível
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error encountered, defaulting to safe value';
    END;

    -- 3. Lógica potencialmente problemática
    --    Divisão por zero → vai disparar o SQLEXCEPTION
    SET sales_total = (
        SELECT SUM(o_totalprice) / 0   -- erro deliberado
        FROM orders
    );

    -- 4. Este SELECT NÃO executa se o erro acima ocorreu
    --    porque o EXIT handler já terminou o bloco
    SELECT sales_total;

END;
```

### O que acontece passo a passo:

1. `sales_total` é declarado
2. O handler é registado (fica "de guarda")
3. O `SET` tenta dividir por zero → erro em runtime
4. Controlo salta imediatamente para o handler
5. O handler corre o `SIGNAL` com a mensagem de fallback
6. Por ser `EXIT`, o bloco principal termina — o `SELECT sales_total` nunca executa

---

## SIGNAL — lançar erros intencionais

`SIGNAL` não serve só para fallbacks no handler. Podes usá-lo directamente para **enforçar regras de negócio**:

```sql
BEGIN
    DECLARE total_orders INT;

    SET total_orders = (SELECT COUNT(*) FROM orders WHERE o_orderdate = CURRENT_DATE);

    IF total_orders = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No orders found for today — pipeline aborted';
    END IF;

    -- Lógica que só corre se houver encomendas
    SELECT * FROM orders WHERE o_orderdate = CURRENT_DATE;

END;
```

---

## Casos de uso reais

- Detectar valores nulos em métricas críticas antes de prosseguir
- Apanhar INSERTs ou UPDATEs falhados em pipelines de dados
- Validar parâmetros de entrada antes de executar lógica pesada
- Fornecer fallbacks quando data quality checks falham
- Enforçar regras de negócio com mensagens de erro descritivas

---

## Diferença entre SIGNAL dentro e fora de um handler

| Contexto | Efeito |
|---|---|
| `SIGNAL` **dentro de um handler** | Relança/transforma o erro com uma mensagem mais útil |
| `SIGNAL` **no corpo principal** | Lança um erro intencional para validação de negócio |

---

## Workflow-Ready Scripting — Putting It All Together

Todos os constructs que estudámos — `BEGIN...END`, variáveis, `IF`/`CASE`, loops, handlers — compõem-se numa unidade:

```
Script SQL = uma ou mais queries  →  um task SQL num Lakeflow Job
```

**O que isso significa na prática:**

Scripts com lógica condicional e tratamento de erros podem ser **agendados como SQL tasks em Lakeflow Workflows**, ao lado de notebooks e dashboards, com suporte a dependências, retries e alertas.

### Exemplo de workflow completo em SQL puro:

```sql
BEGIN
    DECLARE daily_sales DOUBLE;

    -- Calcular métrica do dia
    SET daily_sales = (SELECT SUM(o_totalprice) FROM orders WHERE o_orderdate = CURRENT_DATE);

    -- Validar contra threshold
    IF daily_sales < 100000 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Daily sales below threshold — check pipeline';
    END IF;

    -- Processar dados válidos
    SELECT o_orderkey, o_totalprice
    FROM orders
    WHERE o_orderdate = CURRENT_DATE;

END;
```

Este script pode correr como SQL task num DAG do Lakeflow — sem Python, sem notebooks, sem stored procedures em preview.

---

## Resumo do módulo SQL Scripting in Databricks

| Tópico | Keywords |
|---|---|
| Compound Statements | `BEGIN...END` |
| Variables | `DECLARE`, `SET`, scalar subquery |
| Conditional Logic | `IF...THEN...ELSEIF...ELSE...END IF`, `CASE...WHEN...END` |
| Looping Constructs | `LOOP`, `WHILE`, `REPEAT`, `FOR`, `LEAVE`, `ITERATE` |
| Error Handling | `DECLARE EXIT HANDLER FOR SQLEXCEPTION`, `SIGNAL SQLSTATE` |
| Integração | Scripts como SQL tasks em Lakeflow Jobs |

> **A ideia central:** SQL Scripting permite escrever lógica modular, reutilizável e workflow-integrated directamente em SQL — tornando os scripts tão expressivos quanto código Python procedural, mas dentro do ecossistema SQL do Databricks.
