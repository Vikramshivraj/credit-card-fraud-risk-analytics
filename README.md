# Credit Card Fraud Risk Analytics

End-to-end fraud analytics project: **SQL (SQLite) + Python (pandas, scikit-learn) + risk scoring + dashboard**.
It finds fraud patterns, builds a simple model, and converts probabilities into a **0-100 risk score and
Low / Medium / High risk tiers** that a fraud-operations team could act on.

> Author: *add your name here*  |  Dataset: [Kaggle Credit Card Fraud](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud) (284,807 transactions, 492 fraud, Europe, Sept 2013)

## Results (all numbers come from `data/results.json`, written by the notebook)

| Metric | Value |
|---|---|
| Rows after removing 1,081 exact duplicates | 283,726 |
| Fraud rate | 0.17% |
| ROC-AUC / PR-AUC (test set) | 0.965 / 0.668 |
| At default threshold 0.5: recall / precision | 87.4% / 5.6% (1,486 alerts for 95 frauds) |
| **High tier** (score >= 99, cost-based threshold) | 115 alerts, **75 of 95 frauds caught, 65% precision** |
| Fraud $ caught in High tier | $10,977 of $14,766 total fraud in the test set |
| Medium tier (score 50-99) | 1,371 transactions, 8 frauds |

**Story in one line:** accuracy is useless for 0.17% fraud; the default threshold gives high recall but
about 17 false alerts per real fraud caught, so we pick a **cost-based threshold** and split alerts into tiers to keep the
workload realistic.

## Key findings
1. Fraud is concentrated in relative hours **2-4** (hour 2: 1.45% after de-duplication vs 0.17% overall).
   `Time` is "seconds since the first transaction", so "2 AM" is an assumption.
2. Fraud has a higher *average* amount ($122 vs $88) but a much lower *median* ($9 vs $22): amount alone is not a detector.
3. Accuracy (97.5%) is below the "predict all legit" baseline (99.8%), yet the model is far more useful.
4. Risk tiers turn 1,486 alerts into a 115-row investigation list plus a light-touch Medium queue.
5. 1,081 duplicate rows found in pandas **and** SQL (same count) and removed before modelling.

## Folder structure
```
README.md  requirements.txt  POWERBI_GUIDE.md  .gitignore
data/        creditcard.csv (you download) | risk_scored_transactions.csv | results.json | fraud.db (generated)
notebooks/   fraud_risk_analytics.ipynb      <- the whole project, run top to bottom
sql/         fraud_analysis.sql              <- 10 queries (aggregation, CASE, CTE, subquery, window function)
dashboards/  two PNG dashboard pages (matplotlib)
```

## How to run (VS Code, Windows / Mac / Linux)
1. Download `creditcard.csv` from Kaggle and put it in `data/`.
2. Open the project folder in VS Code and install the *Python* and *Jupyter* extensions.
3. In the VS Code terminal:
```bash
python -m venv .venv
# Windows:        .venv\Scripts\activate
# Mac / Linux:    source .venv/bin/activate
pip install -r requirements.txt
```
4. Open `notebooks/fraud_risk_analytics.ipynb`, choose the `.venv` kernel (top right), click **Run All** (about 1-2 minutes).
5. Run the SQL yourself: install the VS Code extension **SQLite Viewer** (or *SQLTools* + *SQLTools SQLite*), open `data/fraud.db`
   and paste queries from `sql/fraud_analysis.sql`. Or from the terminal:
```bash
python -c "import sqlite3,pandas as pd;c=sqlite3.connect('data/fraud.db');print(pd.read_sql('SELECT RiskLevel,COUNT(*) n FROM scored_transactions GROUP BY 1',c))"
```
6. Optional: build the Power BI version with `POWERBI_GUIDE.md`.

## Method (simple version)
1. **Data quality:** missing values, duplicates, class imbalance.
2. **EDA:** amount and time-of-day patterns.
3. **SQL:** the same questions in SQL, plus CTE, subquery and window-function queries.
4. **Model:** Logistic Regression, `class_weight="balanced"`, scaler inside a `Pipeline` (split first, scale second - no leakage).
   Features: `V1`-`V28`, `Amount`, `is_night`.
5. **Threshold:** chosen on *training* data by cross-validation using an assumed cost rule (missed fraud = its amount, $5 per alert).
6. **Risk score = probability x 100**, tiers: High >= 99, Medium 50-99, Low < 50.

## Limitations (say these before the interviewer does)
- Anonymised PCA features: no merchant, geography, customer history or channel analysis.
- Two days of 2013 data; the 2 AM pattern may not generalise.
- The $5 review cost is an **assumption**; real banks use their own costs.
- Probabilities are inflated by class weighting (not calibrated), so treat the score as a ranking.
- One split and 95 test frauds, so results move with the random seed (try `RANDOM_STATE = 1, 7, 99`).

## Interview cheat-sheet
- *Why not accuracy?* 0.17% fraud: predicting all-legit is 99.8% accurate and catches nothing.
- *Precision vs recall?* Recall = share of frauds caught; precision = share of alerts that are real fraud.
- *PR-AUC vs ROC-AUC?* PR-AUC ignores the huge legit class, so it is more honest when positives are rare.
- *Why drop duplicates?* Identical rows can fall in both train and test and inflate the score.
- *Why scale after the split?* Fitting the scaler on all data leaks test information.
- *How did you choose the threshold?* Minimised an explicit cost on training data, then reported on untouched test data.
- *What would you do next?* XGBoost/LightGBM, calibration, SHAP, velocity features, drift monitoring.
