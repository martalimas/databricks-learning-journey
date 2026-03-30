# SQL Scripting in Databricks — Control Flow with Looping Constructs

> **Pathway 8 · SQL Programming and Procedural Logic**  
> Tópico: Looping Constructs — `LOOP`, `WHILE`, `REPEAT`, `FOR`

---

## Porquê loops em SQL scripting?

SQL standard não tem iteração — ou fazes tudo de uma vez (set-based), ou precisas de outra linguagem. Com SQL Scripting no Databricks, podes repetir operações programaticamente dentro de um `BEGIN...END`, sem sair do SQL. Útil para: data quality checks row-by-row, staged transformations, e validações repetidas.

---

## Os 4 tipos de loop

| Loop | Condição avaliada | Quando usar |
|---|---|---|
| `LOOP` | Nunca — infinito por defeito; sai com `LEAVE` | Quando a condição de saída é complexa ou está no meio do corpo |
| `WHILE` | **Antes** de cada iteração | Quando sabes à partida se o loop deve correr |
| `REPEAT` | **Depois** de cada iteração | Quando o corpo tem de correr pelo menos uma vez |
| `FOR` | Range-based com contador automático | Quando iteras sobre um intervalo ou cursor definido |

### Controlo de fluxo dentro dos loops

| Keyword | Efeito |
|---|---|
| `LEAVE <label>` | Sai do loop imediatamente (equivalente a `break`) |
| `ITERATE <label>` | Salta para a próxima iteração (equivalente a `continue`) |

> Os labels (`orders_loop:`) são opcionais mas essenciais quando há **loops aninhados** — especificam a qual dos loops o `LEAVE`/`ITERATE` se aplica.

---

## Anatomia de um LOOP — exemplo completo

O exemplo dos slides usa `LOOP` (infinito com saída explícita) para iterar sobre as primeiras 5 encomendas da tabela `orders`.

### Progressão passo a passo

**Passo 1 — Declarar as variáveis de controlo**

```sql
BEGIN
    DECLARE i          INT DEFAULT 1;  -- contador: começa em 1
    DECLARE max_orders INT DEFAULT 5;  -- limite: para ao chegar a 5
```

**Passo 2 — Abrir o LOOP com label e cláusula de saída**

```sql
    orders_loop: LOOP

        -- Termination clause: sai quando i ultrapassa max_orders
        IF i > max_orders THEN
            LEAVE orders_loop;
        END IF;
```

**Passo 3 — Corpo do loop: lógica + incremento do contador**

```sql
        -- Executa um SELECT por cada iteração
        SELECT o_orderkey, o_totalprice
        FROM orders
        WHERE o_orderkey = i;

        -- Incrementar o contador (sem isto: loop infinito!)
        SET i = i + 1;

    END LOOP orders_loop;

END;
```

### Bloco completo

```sql
BEGIN
    DECLARE i          INT DEFAULT 1;
    DECLARE max_orders INT DEFAULT 5;

    orders_loop: LOOP

        IF i > max_orders THEN
            LEAVE orders_loop;
        END IF;

        SELECT o_orderkey, o_totalprice
        FROM orders
        WHERE o_orderkey = i;

        SET i = i + 1;

    END LOOP orders_loop;

END;
```

---

## O que este exemplo demonstra

**1. Iteração row-level em SQL puro** — cada passagem do loop executa um `SELECT` diferente, com `i` a mudar. Isto não é possível em SQL standard.

**2. Terminação explícita** — tu defines exactamente quando o loop para (`IF i > max_orders THEN LEAVE`). Não há magia implícita.

**3. Estrutura clara em 3 partes** — dentro de qualquer loop bem escrito encontras sempre:
- condição de saída
- lógica de negócio
- actualização do estado (contador, flag, etc.)

---

## Casos de uso reais

- Verificar qualidade de dados em múltiplas linhas sequencialmente
- Aplicar transformações staged a registos individuais
- Avaliar métricas derivadas ao longo do tempo
- Loops aninhados para lógica multi-nível (com `ITERATE` para saltar casos inválidos)

---

## Referência rápida de sintaxe

```sql
-- LOOP (infinito com LEAVE)
label: LOOP
    -- corpo
    IF <condição> THEN LEAVE label; END IF;
END LOOP label;

-- WHILE (condição antes)
WHILE <condição> DO
    -- corpo
END WHILE;

-- REPEAT (condição depois — corre sempre pelo menos 1x)
REPEAT
    -- corpo
UNTIL <condição>
END REPEAT;

-- FOR (range-based)
FOR i IN 1 TO 10 DO
    -- corpo
END FOR;
```

> **Regra geral:** escolhe `WHILE` quando a condição é simples e conhecida antes do loop. Usa `LOOP` quando precisas de avaliar a condição no meio do corpo ou quando a lógica de saída é composta.
