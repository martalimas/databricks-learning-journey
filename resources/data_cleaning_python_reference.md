# Guia Completo de Data Cleaning
> Resumo de todos os tópicos abordados — para consulta rápida

---

## Índice
1. [Duplicados](#1-duplicados)
2. [Restrições de Intervalo](#2-restrições-de-intervalo)
3. [Membership Constraints](#3-membership-constraints)
4. [Variáveis Categóricas](#4-variáveis-categóricas)
5. [Limpeza de Texto](#5-limpeza-de-texto)
6. [Uniformidade](#6-uniformidade)
7. [Cross Field Validation](#7-cross-field-validation)
8. [Missing Data](#8-missing-data)
9. [String Similarity & Record Linkage](#9-string-similarity--record-linkage)
10. [Onde encaixa na Arquitectura Medallion](#10-onde-encaixa-na-arquitectura-medallion)

---

## 1. Duplicados

```python
# Detetar duplicados
df.duplicated(subset='col', keep=False)

# Remover — fica com a primeira ocorrência
df.drop_duplicates(subset='col', keep='first')

# ATENÇÃO: inplace=True retorna None!
# ❌ df_clean = df.drop_duplicates(inplace=True)
# ✅ df_clean = df.drop_duplicates()

# Duplicados parciais — mesmo ID mas valores diferentes noutras colunas
statistics = {'col_a': 'min', 'col_b': 'mean'}
df_unique = df.groupby('id').agg(statistics).reset_index()
```

---

## 2. Restrições de Intervalo

```python
# Detetar valores fora do intervalo
invalid = df[(df['age'] < 0) | (df['age'] > 120)]

# Remover
df = df[(df['age'] >= 0) & (df['age'] <= 120)]

# Substituir por NaN
import numpy as np
df.loc[(df['age'] < 0) | (df['age'] > 120), 'age'] = np.nan

# Clipar — forçar valores para dentro do intervalo
df['completion_rate'] = df['completion_rate'].clip(0, 100)

# Validar com assert
assert df['age'].max() <= 120
assert df['age'].min() >= 0
```

---

## 3. Membership Constraints

Dados categóricos só podem ter valores de um conjunto pré-definido.

```python
# Referência de categorias válidas
categories = pd.DataFrame({'blood_type': ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']})

# Encontrar valores inválidos (anti join)
inconsistent_categories = set(df['blood_type']).difference(categories['blood_type'])

# Identificar linhas inválidas
inconsistent_rows = df['blood_type'].isin(inconsistent_categories)

# Ver as linhas inválidas
df[inconsistent_rows]

# Remover as linhas inválidas (~ = NOT)
df_clean = df[~inconsistent_rows]
```

---

## 4. Variáveis Categóricas

### 4.1 Capitalização inconsistente
```python
df['col'].value_counts()  # ver o problema
df['col'] = df['col'].str.lower()   # uniformizar para minúsculas
df['col'] = df['col'].str.upper()   # ou maiúsculas
```

### 4.2 Espaços extra
```python
df['col'] = df['col'].str.strip()  # remove espaços no início e no fim
```

### 4.3 Criar categorias de dados numéricos
```python
import pandas as pd
import numpy as np

# cut — intervalos manuais (preferível)
df['income_group'] = pd.cut(df['income'],
                             bins=[0, 30000, 60000, np.inf],
                             labels=['low', 'medium', 'high'])

# qcut — divide automaticamente pela distribuição (cuidado!)
df['income_group'] = pd.qcut(df['income'], q=3,
                              labels=['low', 'medium', 'high'])
```

### 4.4 Reduzir número de categorias
```python
mapping = {
    'Windows': 'DesktopOS',
    'MacOS':   'DesktopOS',
    'Linux':   'DesktopOS',
    'iOS':     'MobileOS',
    'Android': 'MobileOS'
}
df['os'] = df['os'].replace(mapping)
```

---

## 5. Limpeza de Texto

### 5.1 Substituições simples
```python
# Substituir caractere
df['phone'] = df['phone'].str.replace('+', '00')
df['phone'] = df['phone'].str.replace('-', '')
```

### 5.2 Tratar comprimentos inválidos
```python
# Substituir por NaN se tiver menos de 10 dígitos
digits = df['phone'].str.len()
df.loc[digits < 10, 'phone'] = np.nan
```

### 5.3 Regex — casos complexos
```python
# Remover tudo o que não for dígito
df['phone'] = df['phone'].str.replace(r'\D', '', regex=True)

# Padrões úteis:
# \d  → dígito
# \D  → não dígito
# \s  → espaço
# ^   → início da string
# $   → fim da string
```

### 5.4 Validar com assert
```python
assert df['phone'].str.len().min() >= 10
assert df['phone'].str.contains(r'\+|-').any() == False
```

---

## 6. Uniformidade

### 6.1 Unidades mistas
```python
# Exemplo: temperaturas em Celsius e Fahrenheit misturadas
# Converter só as que são Fahrenheit (acima de 40)
df.loc[df['temp'] > 40, 'temp'] = \
    (df.loc[df['temp'] > 40, 'temp'] - 32) * (5/9)

# Validar
assert df['temp'].max() < 40
```

### 6.2 Datas em formatos diferentes
```python
# Converter para datetime — coerce transforma erros em NaT
df['date'] = pd.to_datetime(df['date'], errors='coerce')

# Reformatar
df['date'] = df['date'].dt.strftime('%d-%m-%Y')

# Extrair componentes
df['year']  = df['date'].dt.year
df['month'] = df['date'].dt.month
df['day']   = df['date'].dt.day

# Alternativa com strftime
df['year'] = df['date'].dt.strftime('%Y')
```

> **Datas ambíguas** (ex: 03/08 — Março ou Agosto?): usar contexto da fonte ou converter para NaT.

---

## 7. Cross Field Validation

Usar múltiplas colunas para verificar a integridade dos dados.

### 7.1 Somas entre colunas
```python
# Exemplo: economy + business + first_class deve == total_passengers
sum_classes = flights[['economy', 'business', 'first_class']].sum(axis=1)
# axis=1 → soma por linha (↔️)
# axis=0 → soma por coluna (↕️)

consistent = flights['total_passengers'] == sum_classes
inconsistent_flights = flights[~consistent]
```

### 7.2 Idades vs datas de nascimento
```python
import datetime as dt

df['birthday'] = pd.to_datetime(df['birthday'])
today = dt.date.today()

calculated_age = today.year - df['birthday'].dt.year
consistent = calculated_age == df['age']
inconsistent_users = df[~consistent]
```

### 7.3 O que fazer com inconsistências
| Opção | Quando usar |
|---|---|
| Remover a linha | Sem forma de recuperar o valor |
| Substituir por NaN e imputar | Dados suficientes para estimar |
| Corrigir com regras de domínio | Conhecimento suficiente da fonte |

---

## 8. Missing Data

### 8.1 Deteção
```python
df.isna().sum()              # contar por coluna
df.isna().mean() * 100       # percentagem por coluna
df.info()                     # visão geral
df.isnull().any(axis=1)      # linhas com pelo menos um NaN
```

### 8.2 Visualização
```python
import missingno as msno
import matplotlib.pyplot as plt

msno.matrix(df)               # onde estão os NaN
msno.bar(df)                  # completude por coluna
msno.heatmap(df)              # correlação de missingness entre colunas
msno.dendrogram(df)           # agrupamento por padrão de missingness

# Ordenar para perceber padrões
msno.matrix(df.sort_values('col'))
plt.show()
```

### 8.3 Tipos de missingness
| Tipo | Descrição | Exemplo |
|---|---|---|
| **MCAR** | Completamente aleatório | Erro de digitação |
| **MAR** | Relacionado com outra coluna observada | CO2 em falta a baixas temperaturas |
| **MNAR** | Relacionado com valores não observáveis | Termómetro avaria quando faz muito calor |

### 8.4 Tratamento

#### Remoção
```python
df.dropna()                          # remover linhas com qualquer NaN
df.dropna(subset=['col1', 'col2'])   # só em colunas específicas
df.dropna(thresh=3)                  # manter linhas com >= 3 valores válidos
df = df.loc[:, df.isna().mean() < 0.5]  # remover colunas com >50% NaN
```

#### Imputação simples
```python
df['col'].fillna(df['col'].mean())      # média
df['col'].fillna(df['col'].median())    # mediana
df['col'].fillna(df['col'].mode()[0])   # moda
df['col'].fillna(0)                      # valor fixo
df['col'].fillna(method='ffill')         # forward fill
df['col'].fillna(method='bfill')         # backward fill
```

#### Imputação com sklearn
```python
from sklearn.impute import SimpleImputer, KNNImputer

# SimpleImputer
imputer = SimpleImputer(strategy='mean')  # ou 'median', 'most_frequent'
df_imputed = imputer.fit_transform(df)

# KNNImputer — usa os K vizinhos mais próximos
knn = KNNImputer(n_neighbors=5)
df_imputed = knn.fit_transform(df)
```

#### Imputação avançada
```python
from sklearn.experimental import enable_iterative_imputer
from sklearn.impute import IterativeImputer

# Modela cada coluna NaN em função das outras
imputer = IterativeImputer(max_iter=10, random_state=42)
df_imputed = imputer.fit_transform(df)
```

### 8.5 Boas práticas
```python
# Criar flag antes de imputar — preserva a informação de missingness
df['col_was_missing'] = df['col'].isna().astype(int)

# Comparar distribuição antes e depois
df['col'].hist(alpha=0.5, label='original')
df['col_imputed'].hist(alpha=0.5, label='imputado')
plt.legend()
plt.show()
```

### 8.6 Escolher a abordagem certa
| Situação | Abordagem |
|---|---|
| Poucos NaN e MCAR | `.dropna()` |
| Numérico, distribuição simétrica | Média |
| Numérico com outliers | Mediana |
| Categórico | Moda |
| Dados temporais | `ffill` / `bfill` |
| MAR com relação entre colunas | KNN ou IterativeImputer |
| Dataset complexo, alta precisão | MissForest |

---

## 9. String Similarity & Record Linkage

### 9.1 Minimum Edit Distance
Número mínimo de operações (inserção, remoção, substituição, transposição) para transformar uma string noutra. Quanto menor, mais parecidas são.

### 9.2 thefuzz — comparar strings
```python
from thefuzz import fuzz, process

# Comparar duas strings — score 0 a 100
fuzz.WRatio('reading', 'reeding')         # ex: 93
fuzz.WRatio('Houston Rockets', 'Rockets') # ex: 90

# Comparar com array — devolver N melhores matches
# Cada resultado: ('valor', score, índice)
process.extract('italian', df['cuisine_type'], limit=len(df))

# Melhor match apenas
process.extractOne('italian', df['cuisine_type'])
```

### 9.3 Colapsar categorias com fuzzy matching
```python
categories = ['italian', 'american', 'asian']

for cuisine in categories:
    matches = process.extract(cuisine,
                              restaurants['cuisine_type'],
                              limit=len(restaurants))
    for match, score, idx in matches:
        if score >= 80:  # threshold — ajustar conforme qualidade dos dados
            restaurants.loc[restaurants['cuisine_type'] == match,
                           'cuisine_type'] = cuisine
```

### 9.4 Record Linkage — processo completo
```python
import recordlinkage

# 1. Gerar pares com blocking
indexer = recordlinkage.Index()
indexer.block('state')  # só compara onde 'state' é igual — evita explosão de pares
pairs = indexer.index(census_A, census_B)

# 2. Comparar colunas
compare = recordlinkage.Compare()
compare.exact('date_of_birth', 'date_of_birth', label='date_of_birth')
compare.exact('state', 'state', label='state')
compare.string('name', 'name', threshold=0.85, label='name')
compare.string('address', 'address', threshold=0.85, label='address')
potential_matches = compare.compute(pairs, census_A, census_B)

# 3. Filtrar matches fortes
matches = potential_matches[potential_matches.sum(axis=1) >= 3]

# 4. Extrair índices duplicados
duplicate_rows = matches.index.get_level_values(1)

# 5. Remover duplicados e concatenar
census_B_new = census_B[~census_B.index.isin(duplicate_rows)]
full_census = pd.concat([census_A, census_B_new])
```

### 9.5 Ferramentas em produção
| Ferramenta | Para quê |
|---|---|
| `thefuzz` | Fuzzy matching simples, limpeza de categorias |
| `recordlinkage` | Record linkage académico/análise pontual |
| **Splink** | Produção em escala, usado em governo |
| **Dedupe** | Produção com aprendizagem ativa |
| AWS Entity Resolution | Solução cloud gerida |

---

## 10. Onde encaixa na Arquitectura Medallion

```
BRONZE
└── Ingestão raw — dados como vêm da fonte
    └── Múltiplos formatos, typos, duplicados, NaN

        ↓ SILVER — DATA CLEANING ACONTECE AQUI

└── Normalização
    ├── Capitalização (.str.lower() / .str.upper())
    ├── Espaços (.str.strip())
    ├── Datas uniformes (pd.to_datetime())
    ├── Unidades iguais (conversões)
    └── Categorias limpas (.replace())

└── Qualidade
    ├── Membership constraints
    ├── Cross field validation
    ├── Restrições de intervalo
    └── Missing data tratado

└── Deduplicação
    ├── Duplicados exatos (.drop_duplicates())
    ├── Fuzzy matching (thefuzz)
    └── Record linkage entre fontes (Splink)

        ↓

GOLD
└── Dados confiáveis, únicos, prontos para análise
└── Power BI, ML, relatórios
```

---

## Cheatsheet Rápida

| Problema | Método |
|---|---|
| Duplicados exatos | `.drop_duplicates()` |
| Valores fora do intervalo | `.loc[]` + `np.nan` ou `.clip()` |
| Categorias inválidas | `.isin()` + `~` |
| Capitalização | `.str.lower()` / `.str.upper()` |
| Espaços | `.str.strip()` |
| Criar categorias numéricas | `pd.cut()` / `pd.qcut()` |
| Muitas categorias | `.replace(mapping_dict)` |
| Texto com padrão variável | Regex + `.str.replace()` |
| Unidades mistas | `.loc[]` + fórmula de conversão |
| Datas inconsistentes | `pd.to_datetime(errors='coerce')` |
| Validar colunas relacionadas | `.sum(axis=1)` + comparação |
| Ver missing | `.isna().sum()` + `msno.matrix()` |
| Remover missing | `.dropna()` |
| Imputar missing | `.fillna()` / `KNNImputer` |
| Typos em categorias | `thefuzz` + loop + threshold |
| Ligar DataFrames sem ID | `recordlinkage` / Splink |

---

*Guia gerado com base no curso DataCamp — Data Cleaning in Python*
