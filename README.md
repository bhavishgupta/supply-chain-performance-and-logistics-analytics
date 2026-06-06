# Supply Chain Performance & Logistics Analytics

## Project Overview

Global supply chains generate enormous volumes of transactional data that,
when left unanalyzed, mask critical operational failures in delivery
performance, profitability, and fraud risk. This project applies end-to-end
data analysis on DataCo Global's supply chain operations to surface the
business intelligence that operations, logistics, and finance teams need to
make faster, more confident decisions.

**Business questions driving this analysis:**
- Where is the company losing money, and why?
- Which markets, regions, and shipping modes are underperforming on SLA?
- What is the scale of fraud exposure, and which order patterns signal risk?
- Which customer segments and product categories drive disproportionate value?

---

## Objectives

- Assess end-to-end order fulfillment performance across 5 global markets
- Identify logistics SLA failures and quantify their operational impact
- Analyze profitability at the order, product, and regional level
- Detect anomalous and high-risk orders using statistical profiling
- Develop a KPI framework covering delivery, revenue, margin, and fraud metrics
- Translate findings into prioritized, stakeholder-ready business recommendations

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| Python (Pandas, NumPy) | Data cleaning, transformation, feature engineering |
| SQL (MySQL) | Analytical querying, KPI development, star-schema design |
| Matplotlib & Seaborn | EDA visualizations and business reporting charts |
| Jupyter Notebook | End-to-end analysis environment |

---

## Dataset

**Source:** DataCo Global Supply Chain Dataset  
**Scale:** 180,519 order records · 53 columns · 65,752 unique orders · 2015–2018

The dataset covers the full order lifecycle — customer demographics and
segmentation, product catalog and category data, order financials (sales,
profit, discount), shipment scheduling vs. actual delivery, shipping mode,
geographic market and region, and order status including fraud flags.

---

## Data Cleaning & Preparation

- Removed 6 columns: 100% null fields, zero-variance columns, and PII
  placeholders (Customer Password, Customer Email) with documented justification
- Parsed date strings into datetime objects with explicit format specification
  for time-series accuracy
- Resolved missing values using context-appropriate strategies (median fill
  vs. row retention) based on missingness rate
- Standardized 8 categorical columns for consistent GROUP BY behavior in SQL
- Engineered 12 business KPIs including `delivery_delay_days`,
  `profit_margin_pct`, `discount_band`, `risk_category`, and `is_late_delivery`
- Validated data integrity through duplicate checks, negative-value profiling,
  and distribution audits across all financial columns

---

## Exploratory Data Analysis

- **Sales & Revenue:** Market-level and quarterly revenue breakdown identifying
  LATAM as the highest-revenue market and Q4 as a consistent seasonal peak
- **Profitability:** Category and product-level margin analysis exposing
  discount-driven profit erosion across all customer segments
- **Delivery Performance:** SLA compliance measurement across all shipping
  modes, revealing a Same Day inversion — highest-cost tier with worst
  on-time rate
- **Customer Segmentation:** Comparative analysis of Consumer, Corporate,
  and Home Office segments across revenue, profit, and order frequency
- **Shipping Mode Analysis:** Volume, revenue share, and late delivery rate
  by mode to identify the operational vs. financial trade-offs
- **Product & Category Performance:** ABC/Pareto classification of SKUs by
  revenue contribution and margin efficiency
- **Regional Analysis:** Order fulfillment and profitability benchmarking
  across 23 order regions and 5 global markets
- **Risk & Fraud Profiling:** Statistical outlier detection using 2-sigma
  thresholds to isolate suspected fraud orders by market, payment type,
  and profit deviation

---

## Key Business Insights

1. **Logistics crisis, not isolated delays:** A 57.3% late delivery rate —
   nearly 3× the 20% industry benchmark — signals a systemic carrier
   performance failure, not random exceptions
2. **Premium shipping is broken:** Same Day shipping carries the worst
   on-time performance despite commanding the highest cost — a direct
   driver of churn among the most time-sensitive customers
3. **Discounting is destroying margin:** Orders with discount rates above
   15% are consistently negative-profit; 18.7% of all orders lose money,
   cutting realized margin from a potential ~18% to the actual 10.8%
4. **$830K fraud exposure goes undetected:** 2.25% of orders are flagged
   as suspected fraud, concentrated in specific payment types and
   correlating with maximum negative-profit values
5. **Europe outperforms on efficiency, not just revenue:** Despite ranking
   second in sales, Europe generates the highest profit margin — making it
   the operational benchmark for all other markets
6. **Q4 demand is predictable and underutilized:** Q4 outperforms all
   quarters in both revenue and profit every single year, yet no evidence
   of pre-positioned inventory or pre-negotiated carrier capacity exists
   in the data
7. **Home Office segment is under-served:** Smallest by order volume but
   highest by average order value — a premium niche receiving no
   differentiated commercial treatment

---

## Project Outcomes

This analysis equips supply chain, operations, and finance stakeholders with:

- **Revenue clarity:** Market and product-level performance ranked by actual
  contribution, not just order volume
- **Margin recovery path:** A data-backed case for a 15% discount cap,
  projected to recover $500K+ in annual margin
- **Delivery SLA roadmap:** Carrier-level and mode-level performance data
  needed to renegotiate contracts and reset customer expectations
- **Fraud mitigation framework:** Statistical profiling of high-risk orders
  to inform ML-based fraud scoring at the payment stage
- **Customer strategy inputs:** Segment-level KPIs to design differentiated
  commercial strategies across Consumer, Corporate, and Home Office accounts

---

## Visualizations

> *Dashboard and chart exports available in the `/charts` directory.*

20 business-focused visualizations covering:
- Market and regional revenue/profit comparison
- Monthly and quarterly sales trend analysis
- Late delivery rate by shipping mode and region
- Discount rate vs. profit scatter analysis
- Customer segment and product category performance
- Order status distribution and fulfillment rate
- Risk category and fraud pattern profiling

---

## Conclusion

This project demonstrates that supply chain data, when properly cleaned,
engineered, and analyzed, reveals operational and financial failures that
are invisible in aggregate reporting. The findings — a 57% late delivery
rate, $830K in fraud exposure, and margin-destroying discount patterns —
are not data anomalies; they are business decisions waiting to be corrected.
The analysis framework built here is directly transferable to BI dashboards,
executive reporting pipelines, and predictive operations models.
