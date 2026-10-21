# Rebuild the dashboard in Power BI Desktop (about 1 hour)

The PNGs in `dashboards/` are made with Python. To show **Power BI** on your CV, build this yourself
(Power BI Desktop is free, Windows only).

1. **Get data** -> Text/CSV -> `data/risk_scored_transactions.csv` -> Load.
2. **Add a measure** (Modeling -> New measure). DAX:
   - `Total Txns = COUNTROWS(risk_scored_transactions)`
   - `Fraud Txns = CALCULATE([Total Txns], risk_scored_transactions[ActualOutcome] = "Fraud")`
   - `Fraud Rate % = DIVIDE([Fraud Txns], [Total Txns])`
   - `High Alerts = CALCULATE([Total Txns], risk_scored_transactions[RiskLevel] = "High")`
   - `High Precision % = DIVIDE(CALCULATE([Fraud Txns], risk_scored_transactions[RiskLevel] = "High"), [High Alerts])`
   - `Fraud Recall % = DIVIDE(CALCULATE([Fraud Txns], risk_scored_transactions[RiskLevel] = "High"), [Fraud Txns])`
   - `Fraud $ = CALCULATE(SUM(risk_scored_transactions[TransactionAmount]), risk_scored_transactions[ActualOutcome] = "Fraud")`
3. **Page 1 - Overview:** 4 Card visuals (`Total Txns`, `Fraud Txns`, `High Alerts`, `High Precision %`),
   a column chart (X = `Hour`, Y = `Fraud Rate %`), a donut (Legend = `RiskLevel`, Values = `Total Txns`).
4. **Page 2 - Risk monitoring:** a table (TransactionID, TransactionAmount, RiskScore, RiskLevel) sorted by
   RiskScore descending, a slicer on `RiskLevel`, a clustered bar (Axis = `RiskLevel`, Values = `Fraud Txns`, `Fraud $`).
5. Colours: High = red, Medium = amber, Low = green. Save as `dashboards/fraud_risk.pbix`.
