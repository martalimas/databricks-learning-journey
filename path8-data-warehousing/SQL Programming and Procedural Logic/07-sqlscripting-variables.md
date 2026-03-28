# SQL Scripting in Databricks — Variables in SQL Scripts

> **Pathway 8 · SQL Programming and Procedural Logic**  
> Tópico: Variables in SQL Scripts — `DECLARE` and `SET`

---

## Porquê variáveis?

Variáveis permitem guardar valores — constantes, resultados de queries, flags — e reutilizá-los em múltiplos passos do mesmo script. Tornam o SQL mais expressivo, menos repetitivo, e são essenciais para controlo de fluxo (condicionais, ciclos, tratamento de erros).

---

## Regras fundamentais

| Conceito | Detalhe |
|---|---|
| **Fortemente tipado** | Tens de declarar o tipo explicitamente: `INT`, `STRING`, `DOUBLE`, etc. |
| **Scoped ao bloco** | Variáveis só existem dentro do `BEGIN...END` onde foram declaradas. Quando o bloco termina, a variável é descartada. |
| **Declaração no topo** | `DECLARE` tem de aparecer no topo do bloco — não pode estar aninhado dentro de loops ou condicionais. |
| **Atribuição com `SET`** | O valor pode ser um literal ou o resultado de uma **scalar subquery** (deve retornar exactamente uma linha/coluna). |

---

## Sintaxe base

### 1 — Declarar uma variável

```sql
BEGIN
    DECLARE avg_order_price DOUBLE;
    -- variável existe, mas ainda não tem valor atribuído
END;
```

### 2 — Atribuir um valor com `SET`

```sql
BEGIN
    DECLARE avg_order_price DOUBLE;

    SET avg_order_price = (
        SELECT AVG(o_totalprice) FROM orders
    );
    -- avg_order_price contém agora a média calculada
END;
```

> **Atenção:** O `SET` com scalar subquery falha se a subquery retornar mais do que uma linha ou nenhuma linha. Escreve estas subqueries com cuidado.

### 3 — Usar a variável numa query

```sql
BEGIN
    DECLARE avg_order_price DOUBLE;

    SET avg_order_price = (
        SELECT AVG(o_totalprice) FROM orders
    );

    SELECT o_orderkey, o_totalprice
    FROM orders
    WHERE o_totalprice > avg_order_price;

END;
```

---

## O padrão que vais usar constantemente

```
Calcular algo uma vez  →  guardar na variável  →  reutilizar em lógica posterior
```

Este padrão evita duplicar lógica e torna os scripts muito mais fáceis de manter. Em vez de repetir `(SELECT AVG(...))` em vários sítios, calculas uma vez, guardas, e referencias pelo nome.

---

## Comparação rápida: variável vs. temp view

| | Variável (`DECLARE`) | Temporary View |
|---|---|---|
| Guarda | Um único valor escalar | Um conjunto de linhas (tabela) |
| Usado em | `WHERE`, expressões, condicionais | `FROM`, `JOIN` |
| Escopo | Dentro do `BEGIN...END` | Durante a sessão (ou até `DROP VIEW`) |
| Exemplo | `avg_order_price = 5000.0` | `low_value_orders` (com múltiplas linhas) |

---

## O que vem a seguir

Variáveis com `DECLARE`/`SET` são a base. Nos próximos tópicos vão aparecer em conjunto com:
- **Condicionais** (`IF`/`CASE`) — decisões baseadas no valor da variável
- **Ciclos** (`WHILE`, `FOR`) — variáveis como contadores ou condições de saída
- **Tratamento de erros** — variáveis para capturar códigos de erro

> Tudo começa aqui: `DECLARE` define o espaço, `SET` preenche-o.
