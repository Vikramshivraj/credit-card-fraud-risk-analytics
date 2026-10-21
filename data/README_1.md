# Data folder

| File | What it is | In the zip? |
|---|---|---|
| `creditcard.csv` | Raw Kaggle dataset (284,807 rows). Download: https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud | NO - too big, download yourself |
| `fraud.db` | SQLite database (86 MB) made when you run the notebook (`transactions`, `scored_transactions`) | NO - created by the notebook |
| `risk_scored_transactions.csv` | Model output on the 56,746-row test set: probability, 0-100 score, risk tier, actual outcome | yes |
| `results.json` | Every number quoted in the README, written by the notebook | yes |
