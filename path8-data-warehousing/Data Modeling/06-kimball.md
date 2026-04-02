# Estratégias de Modelação de Dados — Parte 5: Kimball — Dimensional Modeling

> **Módulo:** Data Modeling Strategies  
> **Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner  
> **Âmbito:** Abordagem bottom-up de Kimball, fact tables, dimension tables, star schema, snowflake schema, SCDs

---

## Dimensional Modeling de Ralph Kimball

> *Uma abordagem prática ao Data Warehousing*

Ralph Kimball defende uma abordagem **bottom-up**. A sua técnica de Dimensional Modeling foca-se na **acessibilidade para o utilizador** e no **desempenho**.

### Princípios-Chave

| Princípio | Descrição |
|---|---|
| **Dimensional Design** | Organiza os dados em fact tables e dimension tables |
| **Bus Architecture** | Garante escalabilidade e consistência em todo o data warehouse através de dimensões conformadas partilhadas |
| **Incremental Development** | Constrói o data warehouse de forma iterativa através de data marts |

### Importância

- Enfatiza a facilidade de uso para utilizadores de negócio
- Optimiza o desempenho de queries para reporting e análise

---

## Kimball vs. Inmon

| | Kimball (Bottom-Up) | Inmon (Top-Down) |
|---|---|---|
| **Ponto de partida** | Data marts para processos de negócio específicos | EDW abrangente |
| **Arquitectura** | Data marts integrados com dimensões conformadas | EDW é o repositório do qual derivam os data marts |
| **Vantagens** | Implementação mais rápida, valor imediato para o negócio, flexibilidade | Consistência e integração de dados em toda a empresa |
| **Velocidade** | Entrega resultados mais rapidamente | Mais lento a arrancar |
| **Escalabilidade** | Bom para desenvolvimento iterativo e adaptável | Melhor para iniciativas enterprise de grande escala |

> **Resumo:** Kimball é "começa pequeno, entrega depressa". Inmon é "constrói a fundação certa desde o início".

---

## Conceitos Core do Dimensional Modeling

### Fact Tables — Tabelas de Factos

Tabelas centrais que armazenam dados **quantitativos e mensuráveis** relacionados com processos de negócio.

- Contêm **foreign keys** que referenciam as dimension tables
- Incluem **métricas numéricas** (ex: montante de vendas, quantidade)
- Frequentemente contêm medidas aditivas, semi-aditivas ou não-aditivas

### Dimension Tables — Tabelas de Dimensão

Tabelas envolventes que fornecem **atributos descritivos** relacionados com os dados de factos.

- Contêm informação textual ou categórica (ex: nomes de produtos)
- Frequentemente **desnormalizadas** para optimizar o desempenho de queries
- Suportam relações hierárquicas (ex: datas com ano, trimestre, mês)

---

## Schemas — Star vs. Snowflake

### Star Schema ⭐

```
                    dim_cliente
                        │
                        │
dim_produto ──── fact_vendas ──── dim_data
                        │
                        │
                    dim_loja
```

- **Fact table** no centro, ligada a várias dimension tables
- Dimension tables são **desnormalizadas** (toda a informação numa só tabela)
- Simples, fácil de entender, rápido para queries

### Snowflake Schema ❄️

```
                    dim_cliente
                        │
              dim_produto ──── fact_vendas ──── dim_data
              │                                      │
         dim_categoria                         dim_mes
                                                    │
                                               dim_ano
```

- Extensão do star schema
- As dimension tables são **normalizadas** em múltiplas tabelas relacionadas
- Reduz redundância mas aumenta o número de joins

---

## Desenho de Fact Tables

### Tipos de Fact Tables

| Tipo | O que regista | Exemplo |
|---|---|---|
| **Transactional Facts** | Transacções individuais de negócio | Uma linha por venda, por clique, por encomenda |
| **Periodic Snapshot Facts** | Captura dados em intervalos regulares | Saldo de conta no fim de cada mês |
| **Accumulating Snapshot Facts** | Rastreia a progressão de um processo | Estado de uma encomenda do pedido à entrega |

### Grain Definition — Granularidade

> A definição do **grain** é uma das decisões mais críticas no Kimball.

O grain define o **nível de detalhe** armazenado na fact table — ou seja, o que representa exactamente uma linha.

Exemplos:
- *"Uma linha por item de encomenda"* — grain fino
- *"Uma linha por encomenda"* — grain mais grosso
- *"Uma linha por dia por loja"* — grain de snapshot periódico

### Tipos de Medidas (Measures)

| Tipo | Definição | Exemplo |
|---|---|---|
| **Aditiva** | Pode ser somada em qualquer dimensão | Valor de vendas, quantidade |
| **Semi-Aditiva** | Pode ser somada em algumas dimensões mas não todas | Saldo de conta (soma por cliente mas não por tempo) |
| **Não-Aditiva** | Não pode ser somada | Percentagem, rácio, preço unitário |

### Foreign Keys na Fact Table

- **Papel:** ligar a fact table às dimension tables correspondentes
- **Implementação:** garantem integridade referencial e suportam joins eficientes durante queries

---

## Desenho de Dimension Tables

### Características

| Característica | Descrição |
|---|---|
| **Atributos Descritivos** | Fornecem contexto aos dados de factos (ex: nome do cliente, categoria do produto) |
| **Surrogate Keys** | Identificadores únicos usados em vez das natural keys para gerir mudanças ao longo do tempo |
| **Hierarquias** | Permitem drill-down em relatórios (ex: hierarquias geográficas de país → cidade) |

### Tipos de Dimensões

| Tipo | Descrição | Exemplo |
|---|---|---|
| **Conformed Dimensions** | Partilhadas entre múltiplas fact tables e data marts — garantem consistência | `dim_data` usada em vendas, inventário e RH |
| **Role-Playing Dimensions** | Usadas múltiplas vezes no mesmo schema com papéis diferentes | `dim_data` usada para `order_date` e `ship_date` |
| **Junk Dimensions** | Combinam atributos de baixa cardinalidade não relacionados numa única dimensão — reduzem a confusão nas fact tables | Flags e indicadores (activo/inactivo, prioridade, status) |

### Slowly Changing Dimensions (SCD)

| Tipo | Comportamento | Quando usar |
|---|---|---|
| **SCD Tipo 1** | Sobrescreve os dados antigos com os novos — **não preserva histórico** | Quando o histórico não interessa (ex: correcção de erro) |
| **SCD Tipo 2** | Cria um novo registo para preservar os dados históricos — **preserva histórico completo** | Quando precisas de rastrear mudanças ao longo do tempo (ex: morada do cliente) |

**Exemplo SCD Tipo 2:**
```
dim_cliente
──────────────────────────────────────────────────────────────
sk  │ cliente_id │ nome       │ cidade  │ inicio     │ fim        │ activo
────┼────────────┼────────────┼─────────┼────────────┼────────────┼───────
1   │ C001       │ Marta Lima │ Lisboa  │ 2020-01-01 │ 2024-03-15 │ N
2   │ C001       │ Marta Lima │ Porto   │ 2024-03-16 │ NULL       │ S
```

---

## Star Schema — Design e Boas Práticas

### Estrutura

```
               dim_cliente
               ─────────────
               cliente_sk (PK)
               nome
               segmento
               cidade
                    │
                    │ FK
                    ▼
dim_produto    fact_vendas      dim_data
────────────   ─────────────    ────────────
produto_sk(PK) venda_id (PK)    data_sk (PK)
nome           cliente_sk (FK)  data
categoria      produto_sk (FK)  mes
marca          data_sk (FK)     trimestre
               loja_sk (FK)     ano
               quantidade            │
               valor_total      dim_loja
               desconto         ────────────
                                loja_sk (PK)
                                nome
                                cidade
                                regiao
```

### Vantagens do Star Schema

| Vantagem | Descrição |
|---|---|
| **Simplicidade** | Fácil de compreender e navegar para utilizadores finais e analistas |
| **Desempenho** | Optimizado para operações de leitura intensa — melhora a velocidade das queries |
| **Flexibilidade** | Facilita queries ad-hoc e reporting sem joins complexos |

### Boas Práticas de Design

- **Desnormalizar dimensões** — reduz o número de joins necessários para as queries
- **Usar surrogate keys** — mantém consistência e gere mudanças de forma eficaz
- **Garantir dimensões conformadas** — promove reutilização e consistência entre diferentes fact tables e data marts

---

## Snowflake Schema — Design

### Estrutura

As dimension tables são normalizadas — por exemplo, `dim_produto` divide-se em `dim_produto` + `dim_categoria` + `dim_marca`.

### Vantagens

- **Eficiência de armazenamento** — reduz redundância de dados, poupando espaço
- **Integridade dos dados** — mantém consistência através de tabelas normalizadas

### Desvantagens

- **Complexidade** — aumenta o número de joins necessários para queries, podendo impactar desempenho
- **Manutenção** — mais complexo de gerir e compreender face ao star schema

### Quando usar Snowflake

| Situação | Porquê |
|---|---|
| Dimensões grandes e complexas | A normalização pode reduzir significativamente a redundância |
| Requisitos estritos de integridade de dados | Garante consistência através de tabelas normalizadas |

> **Regra geral no Databricks/Lakehouse:** preferir **star schema** na camada Gold — a desnormalização é intencional para optimizar o desempenho de queries. O snowflake pode ser considerado em Silver quando a integridade é mais importante que a performance.

---

## Resumo Kimball — Pontos-Chave para o Exame

| Conceito | Detalhe |
|---|---|
| Abordagem | **Bottom-up** — data marts primeiro, integração depois |
| Modelo core | **Star schema** — fact table central + dimension tables desnormalizadas |
| Fact table | Métricas quantitativas + FKs para dimensões; define o grain |
| Dimension table | Atributos descritivos + surrogate keys + hierarquias |
| Tipos de medidas | Aditiva / Semi-aditiva / Não-aditiva |
| SCD Tipo 1 | Sobrescreve — sem histórico |
| SCD Tipo 2 | Nova linha — histórico completo |
| Conformed Dimensions | Partilhadas entre data marts — chave da Bus Architecture |
| Star vs. Snowflake | Star = mais simples e rápido; Snowflake = mais normalizado mas mais joins |
| No Databricks | Gold layer = star schema desnormalizado; Silver = pode ser mais normalizado |

---

