# SQL Scripting in Databricks — Compound Statements

**Módulo:** SQL Programming and Procedural Logic  
**Secção:** SQL Scripting in Databricks  
**Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner

---

## Contexto: SQL Scripting em Databricks

**SQL Scripting** em Databricks segue o standard **SQL/PSM** (Persistent Stored Modules) e foi disponibilizado em **Public Preview no Databricks Runtime 16.3+** (Março 2025).

Representa um passo significativo para profissionais com background em RDBMS — traz constructs procedurais familiares (control flow, variáveis, error handling) para dentro do SQL nativo do Databricks.

**O que oferece:**
- Agrupa múltiplos statements SQL num único script com `BEGIN...END`
- Adiciona constructs procedurais: variáveis, controlo de fluxo, error handling
- Disponível em Databricks Runtime 16.3+

---

## Compound Statements — `BEGIN...END`

Um **Compound Statement** é o bloco fundamental do SQL Scripting em Databricks. Agrupa múltiplos comandos SQL numa única unidade de execução.

**Características principais:**
- Agrupa múltiplos comandos SQL dentro de um único bloco de execução
- Encapsula constructs de scripting como variáveis, control flow e error handlers
- Funciona como um lightweight procedure body — ideal para lógica modular
- **Scope local**: variáveis e views declaradas dentro do bloco só existem dentro do bloco

> **Regra importante:** o Databricks **requer** um bloco `BEGIN...END` sempre que queres usar features de scripting como variáveis, control flow ou error handlers. Sem ele, esses constructs não funcionam.

---

## Anatomia de um Compound Statement

```sql
BEGIN
  -- Passo 1: criar uma temp view dentro do bloco
  CREATE OR REPLACE TEMP VIEW high_value_orders AS
  SELECT o_orderkey, o_totalprice
  FROM orders
  WHERE o_totalprice > 100000;

  -- Passo 2: operar imediatamente sobre o resultado
  SELECT COUNT(*) AS high_value_count
  FROM high_value_orders;
END;
```

### As três partes:

| Parte | O que faz |
|---|---|
| `BEGIN` | Abre o bloco de scripting |
| Statements dentro | Executam em sequência como uma unidade lógica |
| `END;` | Fecha formalmente o bloco — obrigatório |

---

## Porquê usar Compound Statements?

**Fora** de um bloco `BEGIN...END`, terias de executar cada statement manualmente, um de cada vez. **Dentro** do bloco, executam como uma unidade lógica — podes sequenciar lógica: primeiro definir, depois operar.

Este padrão — **primeiro criar, depois usar** — é o core do scripting. E é o que desbloqueia tudo o resto:

| Feature | Precisa de BEGIN...END? |
|---|---|
| Variáveis (`DECLARE`) | ✅ Sim |
| Control flow (`IF`, `CASE`) | ✅ Sim |
| Loops (`FOR`, `WHILE`) | ✅ Sim |
| Error handling (`EXCEPTION`) | ✅ Sim |
| Temp Views simples | ❌ Não (mas beneficiam de estar num bloco) |

> Pensa em `BEGIN...END` como o **contentor** que activa o modo scripting. Vais usá-lo em todos os exemplos desta secção.

---

## Compound Statements vs outras abordagens

| | Compound Statement | Notebook cells | CTE |
|---|---|---|---|
| **Múltiplos statements** | ✅ Num único bloco | ✅ Células separadas | ❌ Apenas queries |
| **Variáveis** | ✅ | ❌ | ❌ |
| **Control flow** | ✅ | ❌ | ❌ |
| **Scope local** | ✅ Variáveis morrem com o bloco | ❌ Persistem na sessão | N/A |
| **Runtime mínimo** | DBR 16.3+ | Qualquer | Qualquer |

---

## Key takeaways

- `BEGIN...END` é o **entry point** para SQL Scripting em Databricks — sem ele, nenhum construct procedural funciona
- Disponível desde **DBR 16.3** (Março 2025) — feature recente, ainda em Public Preview
- Segue o standard **SQL/PSM** — familiar para quem vem de Oracle, SQL Server, ou PostgreSQL
- Scope local significa que variáveis declaradas dentro do bloco **não vazam** para fora — comportamento mais seguro e previsível
- É a base sobre a qual se constroem variáveis, loops, conditionals e error handling nas secções seguintes
