# Combinando Abordagens — Avaliação de Modelos DWH
**Módulo:** Modern Data Architecture Use Cases — Lecture  
**Tema:** Combining Approaches / Assessing DWH Models  

---

## Avaliação dos Paradigmas de Modelação DWH

Os três paradigmas principais — **Inmon**, **Kimball** e **Data Vault 2.0** — têm características distintas em três dimensões-chave. Os exemplos abaixo são ilustrativos, não exaustivos.

---

### 1. Capacidade de Mudança *(Ability to Change)*

| Paradigma | Comportamento face a mudanças de negócio |
|---|---|
| **Inmon** | Grande impacto — mudanças de processos de negócio requerem **maior esforço e duração** |
| **Kimball** | Mudanças significativas podem **quebrar a base do modelo** — também maior esforço e duração |
| **Data Vault 2.0** | A estrutura facilita a adaptação a mudanças — **menor esforço** |

---

### 2. Complexidade *(Complexity)*

| Paradigma | Natureza da complexidade |
|---|---|
| **Inmon** | ETL muito complexo com dependências de carga; requer otimizações de fluxo ou jobs ETL adicionais para garantir consistência do modelo |
| **Kimball** | Popular as dimensões pode ser difícil; a lógica de dimensões é complexa, especialmente **Slowly Changing Dimensions (SCD) Type 2 e superiores** |
| **Data Vault 2.0** | Tem **3 a 6× mais objectos** que um DW em 3NF puro; porém o ETL é simplificado, facilmente automatizado e pode **correr em paralelo** |

---

### 3. Robustez *(Robustness)*

| Paradigma | Resistência a alterações |
|---|---|
| **Inmon** | Pode quebrar facilmente com mudanças em processos e regras de negócio |
| **Kimball** | O modelo mais simples de compreender, mas uma massa crítica de mudanças obriga a **remodelar grandes porções** |
| **Data Vault 2.0** | A maioria das mudanças pode ser **compartimentalizada** numa camada específica, sem afectar o resto |

---

## Vantagens de Cada Modelo

### Inmon
- **Estrutura normalizada** — reduz redundância de dados
- **Single Source of Truth** — o DW é concebido como repositório integrado único
- **Adequado para grandes EDW** (*Enterprise Data Warehouses*) — recomendado para integração de dados à escala empresarial

### Kimball
- **Optimizado para reporting e analytics** — os modelos dimensionais foram desenhados especificamente para querying eficiente
- **Fácil de compreender** — os utilizadores de negócio acham o star schema / snowflake schema intuitivos
- **Adequado para projectos menores** — mais rápido de implementar para data marts de menor escala

### Data Vault 2.0
- **Flexibilidade operacional** — permite manter-se próximo da fonte de dados, tornando o sistema auditável e escalável
- **Fácil de adicionar novas fontes** — acomoda novas origens de dados sem reestruturação
- **Rastreamento histórico** — suporte nativo para dados históricos (*inherent historical tracking*)

---

## Desafios de Cada Modelo

### Inmon
- **Complexidade** — difícil de implementar e manter
- **Performance de queries mais lenta** — estruturas normalizadas requerem mais joins
- **Menos intuitivo para utilizadores de negócio** — a estrutura normalizada não é imediatamente legível

### Kimball
- **Redundância de dados** — a desnormalização pode criar desafios de manutenção
- **Sem Single Source of Truth** — os data marts são organizados por área de negócio, podendo gerar múltiplas versões do mesmo dado

### Data Vault 2.0
- **Não ideal para análise e reporting directo** — pode ser necessário usar dimensional modeling para virtual data marts
- **Complexidade** — os modelos podem tornar-se complexos, especialmente ao popular data marts directamente
- **Joins e recursões** — popular data marts a partir do Data Vault pode envolver joins e recursões complexas

---

## Desafios Comuns na Modelação DWH

### A Atracção do "Sem Modelação" *(No Modeling)*

Muitas organizações acham difícil gerir o ciclo de vida dos modelos de dados. Os desafios manifestam-se em três dimensões:

- **Pessoas:** Manter uma base de dados requer DBAs ou data engineers; modelar requer data modelers; fazer um modelo "correcto" requer acesso ao negócio
- **Processo:** O overhead de fazer data modelers colaborarem com o negócio, somado ao tempo de introduzir mudanças, prejudica a capacidade de adaptação a novas condições
- **Tecnologia:** Ferramentas e plataformas que suportem a evolução do modelo ao longo do tempo

> **O dilema central:**  
> Contornar o processo de modelação tem efeitos secundários — **a correcção e qualidade dos dados degradam-se**, sendo trocadas por velocidade e agilidade. É uma trade-off que tem custos a médio/longo prazo.

---

## Resumo Comparativo

| Dimensão | Inmon | Kimball | Data Vault 2.0 |
|---|---|---|---|
| **Facilidade de mudança** | ❌ Baixa | ❌ Baixa | ✅ Alta |
| **Complexidade ETL** | ❌ Alta | ⚠️ Média-Alta | ⚠️ Alta mas paralelizável |
| **Robustez** | ❌ Frágil | ⚠️ Simples mas rígido | ✅ Compartimentalizado |
| **Optimizado para reporting** | ❌ Não directo | ✅ Sim | ❌ Requer camada extra |
| **Histórico nativo** | ⚠️ Com esforço | ⚠️ SCD complexo | ✅ Sim |
| **Escala empresarial** | ✅ Sim | ⚠️ Melhor para projectos menores | ✅ Sim |
| **Intuitividade para negócio** | ❌ Baixa | ✅ Alta | ❌ Baixa |

---

## Para o Exame

- **Data Vault** é o paradigma com **menor esforço de adaptação** a mudanças de negócio — estrutura compartimentalizada.
- **Kimball** é o mais fácil de compreender para utilizadores de negócio, mas quebra com mudanças significativas.
- **Inmon** é o mais adequado para grandes EDW integrados, mas é o mais frágil e complexo de manter.
- O "no modeling" pode parecer ágil a curto prazo, mas compromete **qualidade e correcção dos dados**.
- Data Vault tem mais objectos (3–6× vs. 3NF), mas o ETL é **simplificado e paralelizável**.
