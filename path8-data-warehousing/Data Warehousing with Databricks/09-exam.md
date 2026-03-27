# Databricks Data Warehousing — Quiz Results
**Score: 80/100** (16/20 corretas)

---

## ✅ Respostas corretas

**Q1.** What determines the base capacity necessary for consistent performance in a SQL Warehouse?
> **Minimum clusters setting.**

**Q2.** Which entity can a Unity Catalog Metastore be assigned to?
> **Multiple Databricks Workspaces.**

**Q3.** When using Databricks SDK for Python, what is the difference between `run_now()` and `run_now_and_wait()`?
> **`run_now_and_wait()` blocks execution until job completion, while `run_now()` triggers asynchronously.**

**Q5.** What is the highest level securable object in the Unity Catalog hierarchy?
> **Metastore.**

**Q7.** When configuring notification settings for Lakeflow jobs, which event types can trigger notifications?
> **Start, success, failure, and duration threshold exceeded.**

**Q9.** What is the key difference between notebook tasks and SQL tasks in Lakeflow jobs?
> **Notebook tasks execute notebooks, while SQL tasks execute individual SQL queries.**

**Q10.** Which technique is recommended for real-time data ingestion in Databricks?
> **Auto Loader.**

**Q11.** Which SQL Warehouse type offers users the most complete control over their compute resources?
> **SQL Classic.**

**Q12.** What is the primary purpose of parameterized notebooks with syntax like `${catalog}.${wh_db}.${table}`?
> **To enable notebook portability and reusability across environments.**

**Q13.** In Unity Catalog, what happens to permissions when you grant `SELECT` at the schema level?
> **The permission applies to all current and future tables in that schema.**

**Q14.** What is the primary purpose of the Medallion Architecture in Databricks?
> **To organize data into layers for incremental refinement and analytics.**

**Q15.** Which feature handles records that do not adhere to the defined schema when using Auto Loader?
> **The rescue data column.**

**Q16.** In Unity Catalog's security model, what is the key difference between explicit and inherited privileges?
> **Explicit privileges are granted directly on objects, while inherited privileges flow down from parent containers.**

**Q17.** The COPY INTO command can automatically handle which change management feature?
> **Schema changes.**

**Q18.** What is the primary benefit of using file arrival triggers for Lakeflow jobs?
> **They enable event-driven processing when new data becomes available.**

**Q19.** A Materialized View (MV) can be built on top of Streaming Tables to achieve:
> **Accelerated query speed with pre-computed results.**

---

## ❌ Respostas erradas — rever

**Q4.** When sharing AI/BI dashboards with the "Share data permission" option, what is the key security consideration?
- ❌ Minha resposta: *Unexpected schema evolution*
- ✅ Resposta correta: **Resource bottlenecks.**
- 📝 *Quando partilhas dados diretamente no dashboard, todos os utilizadores correm queries contra o mesmo warehouse — pode criar bottlenecks de recursos.*

---

**Q6.** Change Data Capture (CDC) enables streaming what specific type of modifications from a source system?
- ❌ Minha resposta: *Entire table metadata snapshots*
- ✅ Resposta correta: **Row-level changes.**
- 📝 *CDC captura inserções, atualizações e eliminações ao nível da linha — não snapshots completos da tabela.*

---

**Q8.** How does Serverless SQL manage instance types and configurations?
- ❌ Minha resposta: *Configuration is fixed upon metastore creation*
- ✅ Resposta correta: **Automatically determined for best price/performance.**
- 📝 *É precisamente o ponto central do Serverless: o utilizador não configura instâncias — o Databricks faz o right-sizing automaticamente.*

---

**Q20.** In AI/BI dashboards, what is the main difference between draft and published modes?
- ❌ Minha resposta: *Published dashboards cannot be edited or updated*
- ✅ Resposta correta: **Draft changes don't affect the published version until explicitly published.**
- 📝 *Podes continuar a editar o dashboard em draft sem perturbar quem está a usar a versão publicada — são espaços separados.*
