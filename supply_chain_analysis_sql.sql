/*
===============================================================================
SUPPLY CHAIN PERFORMANCE & LOGISTICS ANALYTICS
SQL Analysis Portfolio | DataCo Global Supply Chain Dataset
Dialect: MySQL 8.0+
===============================================================================

HOW TO USE
1. Load the cleaned dataset into MySQL as `supply_chain_orders`.
2. Confirm column names against your imported table before running queries.
3. Run each section independently.
4. Every query includes:
   - Business Question
   - SQL Query
   - Business Insight / Interpretation
   - Business Recommendation

DATA GRAIN / INTERPRETATION NOTES
- The DataCo source contains order-item-level rows, not necessarily one row per
  distinct order. Use COUNT(DISTINCT order_id) when counting orders.
- SUM(sales) and SUM(profit_per_order) follow the source project's definitions.
  Confirm whether financial measures are repeated across order items before
  presenting totals as order-level figures.
- Delivery Status is used for the source-reported delivery categories; engineered
  delay calculations use actual and scheduled shipping days.
- Fraud-related results are indicators for review, not proof of fraud.
- Findings in comments are hypotheses / interpretations from the project report.
  Re-run the queries on the final cleaned table to validate all figures.

EXPECTED TABLE
`supply_chain_orders`

Common expected columns (adjust names if your import differs):
order_id, order_item_id, customer_id, product_id, product_name, category_name,
department_name, market, order_region, order_country, customer_segment,
sales, order_item_total, profit_per_order, discount_rate, payment_type,
shipping_mode, delivery_status, order_status, actual_shipping_days,
scheduled_shipping_days, late_delivery_risk, order_date, shipping_date,
order_quantity, item_profit_ratio

===============================================================================
SECTION 1 — DATASET BASELINE & OVERVIEW
===============================================================================
*/

-- Q01. What is the size and coverage of the dataset?
-- Business Question: How much data is available for analysis?
-- Business Insight: Establishes the row count, distinct order count, and
-- customer coverage before deeper analysis.
-- Business Recommendation: Record these baseline counts in the README and
-- refresh them whenever the source data is updated.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM supply_chain_orders;


-- Q02. What are the total sales, profit, and overall profit margin?
-- Business Question: What is the high-level financial performance?
-- Business Insight: Provides a baseline for comparing markets, products,
-- customer segments, and time periods.
-- Business Recommendation: Track revenue, profit, and margin together; revenue
-- growth alone can hide deteriorating profitability.
SELECT
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit_per_order), 2) AS total_profit,
    ROUND(100.0 * SUM(profit_per_order) / NULLIF(SUM(sales), 0), 2)
        AS profit_margin_pct
FROM supply_chain_orders;


-- Q03. Which delivery status categories exist and how common are they?
-- Business Question: How are records distributed across delivery outcomes?
-- Business Insight: Highlights the relative scale of late, on-time, advance,
-- and cancelled delivery categories present in the data.
-- Business Recommendation: Agree on a consistent status definition and monitor
-- each category in a weekly operations dashboard.
SELECT
    delivery_status,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM supply_chain_orders), 2)
        AS pct_of_item_rows
FROM supply_chain_orders
GROUP BY delivery_status
ORDER BY item_rows DESC;


/*
===============================================================================
SECTION 2 — MARKET & REGIONAL PERFORMANCE
===============================================================================
*/

-- Q04. Which markets generate the most sales?
-- Business Question: Which geographic markets contribute the most revenue?
-- Business Insight: The source report identifies LATAM and Europe as major
-- revenue contributors and Africa as the smallest market.
-- Business Recommendation: Protect service levels in major markets and assess
-- smaller markets using growth, margin, and fulfilment-cost evidence.
SELECT
    market,
    ROUND(SUM(sales), 2) AS total_sales,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM supply_chain_orders
GROUP BY market
ORDER BY total_sales DESC;


-- Q05. Which markets generate the most profit and margin?
-- Business Question: Does the revenue-leading market also lead in profit?
-- Business Insight: Revenue rank and profit rank can differ; the source report
-- describes Europe as a strong profit performer relative to its sales rank.
-- Business Recommendation: Compare operating practices, discounting, and
-- logistics costs in higher-margin markets with lower-margin markets.
SELECT
    market,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit_per_order), 2) AS total_profit,
    ROUND(100.0 * SUM(profit_per_order) / NULLIF(SUM(sales), 0), 2)
        AS profit_margin_pct
FROM supply_chain_orders
GROUP BY market
ORDER BY total_profit DESC;


-- Q06. Which regions generate the most sales?
-- Business Question: Which order regions are the largest revenue contributors?
-- Business Insight: Reveals where demand and revenue are geographically
-- concentrated.
-- Business Recommendation: Use the result to prioritize regional service-level
-- reviews and investigate capacity needs; do not infer growth potential from
-- revenue alone.
SELECT
    order_region,
    ROUND(SUM(sales), 2) AS total_sales,
    COUNT(DISTINCT order_id) AS unique_orders
FROM supply_chain_orders
GROUP BY order_region
ORDER BY total_sales DESC
LIMIT 10;


-- Q07. How does revenue mix vary by region and customer segment?
-- Business Question: Which customer segments contribute revenue in each region?
-- Business Insight: The source report indicates Consumer is a major contributor
-- across many regions, while regional segment mix can reveal B2B opportunities.
-- Business Recommendation: Target corporate-account development only after
-- validating segment contribution and regional profitability.
SELECT
    order_region,
    customer_segment,
    ROUND(SUM(sales), 2) AS segment_sales,
    ROUND(
        100.0 * SUM(sales) /
        NULLIF(SUM(SUM(sales)) OVER (PARTITION BY order_region), 0), 2
    ) AS pct_of_region_sales
FROM supply_chain_orders
GROUP BY order_region, customer_segment
ORDER BY order_region, segment_sales DESC;


/*
===============================================================================
SECTION 3 — DELIVERY & LOGISTICS PERFORMANCE
===============================================================================
*/

-- Q08. What is the late-delivery rate by shipping mode?
-- Business Question: Which shipping modes have the weakest delivery performance?
-- Business Insight: The source report flags a potential service-level mismatch
-- in which premium modes may still have substantial late deliveries.
-- Business Recommendation: Audit late-delivery causes by carrier, region, and
-- fulfilment process before changing service promises or shipping-mode policy.
SELECT
    shipping_mode,
    COUNT(*) AS item_rows,
    SUM(CASE
            WHEN LOWER(delivery_status) LIKE '%late%' THEN 1
            ELSE 0
        END) AS late_rows,
    ROUND(
        100.0 * SUM(CASE
                        WHEN LOWER(delivery_status) LIKE '%late%' THEN 1
                        ELSE 0
                    END) / NULLIF(COUNT(*), 0), 2
    ) AS late_delivery_pct
FROM supply_chain_orders
GROUP BY shipping_mode
ORDER BY late_delivery_pct DESC;


-- Q09. What is the late-delivery rate by market?
-- Business Question: Where is delivery performance weakest geographically?
-- Business Insight: Identifies markets where logistics execution may be
-- undermining customer experience.
-- Business Recommendation: Prioritize root-cause analysis in markets with both
-- high late-delivery rates and material order volume.
SELECT
    market,
    COUNT(*) AS item_rows,
    SUM(CASE WHEN LOWER(delivery_status) LIKE '%late%' THEN 1 ELSE 0 END)
        AS late_rows,
    ROUND(
        100.0 * SUM(CASE WHEN LOWER(delivery_status) LIKE '%late%' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS late_delivery_pct
FROM supply_chain_orders
GROUP BY market
ORDER BY late_delivery_pct DESC;


-- Q10. What is the average actual shipping duration by shipping mode?
-- Business Question: How long does shipping take under each service mode?
-- Business Insight: Compares actual fulfilment duration across service levels.
-- Business Recommendation: Compare actual duration with the service promise and
-- investigate modes whose delivery speed does not match their positioning.
SELECT
    shipping_mode,
    ROUND(AVG(actual_shipping_days), 2) AS avg_actual_shipping_days,
    ROUND(AVG(scheduled_shipping_days), 2) AS avg_scheduled_shipping_days,
    ROUND(AVG(actual_shipping_days - scheduled_shipping_days), 2)
        AS avg_delay_days
FROM supply_chain_orders
GROUP BY shipping_mode
ORDER BY avg_delay_days DESC;


-- Q11. What is the distribution of delivery delay in days?
-- Business Question: How early or late are shipments relative to schedule?
-- Business Insight: Positive delay indicates late delivery, zero indicates
-- on-time delivery, and negative delay indicates early delivery.
-- Business Recommendation: Use the distribution to set realistic delivery
-- promises and prioritize the most frequent delay values for root-cause review.
SELECT
    actual_shipping_days - scheduled_shipping_days AS delivery_delay_days,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM supply_chain_orders
GROUP BY actual_shipping_days - scheduled_shipping_days
ORDER BY delivery_delay_days;


-- Q12. Which order statuses represent potential processing bottlenecks?
-- Business Question: How many records are in each order-processing status?
-- Business Insight: Large pending, payment, or hold categories may indicate
-- delays between order placement, payment, and fulfilment.
-- Business Recommendation: Establish ageing rules and escalation workflows for
-- unresolved orders; validate elapsed time before claiming a status is overdue.
SELECT
    order_status,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM supply_chain_orders), 2)
        AS pct_of_item_rows
FROM supply_chain_orders
GROUP BY order_status
ORDER BY item_rows DESC;


/*
===============================================================================
SECTION 4 — PRODUCT, CATEGORY & INVENTORY ANALYSIS
===============================================================================
*/

-- Q13. Which 10 products generate the most sales?
-- Business Question: Which products contribute most to revenue?
-- Business Insight: Revenue concentration in a small number of products can
-- increase the impact of stockouts or supplier disruption.
-- Business Recommendation: Review availability, lead times, and supplier
-- resilience for leading products; calculate concentration share before
-- introducing a formal safety-stock policy.
SELECT
    product_id,
    product_name,
    ROUND(SUM(sales), 2) AS total_sales,
    SUM(order_quantity) AS units_ordered
FROM supply_chain_orders
GROUP BY product_id, product_name
ORDER BY total_sales DESC
LIMIT 10;


-- Q14. Which product categories have the strongest profit margins?
-- Business Question: Which categories perform well on margin, not just sales?
-- Business Insight: Category-level margins can vary, and negative-margin
-- categories may be eroding overall profitability.
-- Business Recommendation: Review low-margin categories at SKU level and
-- validate cost, returns, and discount treatment before repricing.
SELECT
    category_name,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit_per_order), 2) AS total_profit,
    ROUND(100.0 * SUM(profit_per_order) / NULLIF(SUM(sales), 0), 2)
        AS profit_margin_pct
FROM supply_chain_orders
GROUP BY category_name
ORDER BY profit_margin_pct DESC;


-- Q15. Which products have negative aggregate profit?
-- Business Question: Which products are loss-making overall?
-- Business Insight: A negative aggregate profit result can identify products
-- requiring commercial or operational review.
-- Business Recommendation: Investigate purchase cost, discounting, shipping,
-- returns, and product mix before deciding to reprice or discontinue a product.
SELECT
    product_id,
    product_name,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit_per_order), 2) AS total_profit,
    ROUND(100.0 * SUM(profit_per_order) / NULLIF(SUM(sales), 0), 2)
        AS profit_margin_pct
FROM supply_chain_orders
GROUP BY product_id, product_name
HAVING SUM(profit_per_order) < 0
ORDER BY total_profit ASC;


-- Q16. What is the distribution of ordered quantities?
-- Business Question: Are orders mostly small-quantity or bulk purchases?
-- Business Insight: The source report notes that observed quantities are within
-- a small range, which may indicate limited bulk-order behaviour in this data.
-- Business Recommendation: Validate the order grain and business model before
-- proposing wholesale pricing or a B2B ordering feature.
SELECT
    order_quantity,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM supply_chain_orders
GROUP BY order_quantity
ORDER BY order_quantity;


/*
===============================================================================
SECTION 5 — DISCOUNTS & PROFITABILITY
===============================================================================
*/

-- Q17. How does average profit change with discount bands?
-- Business Question: Are higher discounts associated with lower profit?
-- Business Insight: This groups discounts into interpretable bands to assess
-- whether deeper discounts coincide with margin erosion.
-- Business Recommendation: Introduce discount guardrails only after checking
-- both profit and sales volume; correlation alone does not prove causation.
SELECT
    CASE
        WHEN discount_rate IS NULL THEN 'Unknown'
        WHEN discount_rate = 0 THEN 'No Discount'
        WHEN discount_rate <= 0.10 THEN 'Low (0-10%)'
        WHEN discount_rate <= 0.20 THEN 'Medium (10-20%)'
        WHEN discount_rate <= 0.30 THEN 'High (20-30%)'
        ELSE 'Very High (>30%)'
    END AS discount_band,
    COUNT(*) AS item_rows,
    ROUND(AVG(discount_rate) * 100, 2) AS avg_discount_pct,
    ROUND(AVG(profit_per_order), 2) AS avg_profit_per_row,
    ROUND(SUM(profit_per_order), 2) AS total_profit
FROM supply_chain_orders
GROUP BY discount_band
ORDER BY MIN(discount_rate);


-- Q18. What proportion of records have negative profit?
-- Business Question: How widespread are negative-profit records?
-- Business Insight: The project report identifies negative-profit rows as an
-- important profitability issue; this query measures the current table.
-- Business Recommendation: Break negative-profit results down by product,
-- category, market, and discount band to find actionable drivers.
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN profit_per_order < 0 THEN 1 ELSE 0 END)
        AS negative_profit_rows,
    ROUND(
        100.0 * SUM(CASE WHEN profit_per_order < 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS negative_profit_row_pct,
    ROUND(SUM(CASE WHEN profit_per_order < 0 THEN profit_per_order ELSE 0 END), 2)
        AS total_negative_profit
FROM supply_chain_orders;


-- Q19. Which customer segments contribute most to sales and profit?
-- Business Question: How do Consumer, Corporate, and Home Office segments compare?
-- Business Insight: Total contribution and average performance answer different
-- questions; high-volume segments may lead totals while another segment leads
-- average value or profit per row.
-- Business Recommendation: Tailor retention, account management, and pricing
-- experiments by segment, using both total contribution and unit economics.
SELECT
    customer_segment,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit_per_order), 2) AS total_profit,
    ROUND(AVG(sales), 2) AS avg_sales_per_row,
    ROUND(AVG(profit_per_order), 2) AS avg_profit_per_row
FROM supply_chain_orders
GROUP BY customer_segment
ORDER BY total_sales DESC;


-- Q20. What is the average order-item value by payment type?
-- Business Question: Does average value differ across payment methods?
-- Business Insight: Similar average values across payment types would suggest
-- payment type may be more useful for checkout and risk analysis than value
-- segmentation.
-- Business Recommendation: Optimize payment UX and evaluate risk rates by
-- payment type rather than assuming payment method predicts order value.
SELECT
    payment_type,
    COUNT(*) AS item_rows,
    ROUND(AVG(order_item_total), 2) AS avg_order_item_value,
    ROUND(SUM(sales), 2) AS total_sales
FROM supply_chain_orders
GROUP BY payment_type
ORDER BY avg_order_item_value DESC;


/*
===============================================================================
SECTION 6 — FRAUD-RISK REVIEW
===============================================================================
*/

-- Q21. How many records and orders are marked as suspected fraud?
-- Business Question: What is the prevalence of the suspected-fraud status?
-- Business Insight: Quantifies the records requiring investigation; the status
-- is a risk flag and does not by itself prove fraud.
-- Business Recommendation: Route flagged transactions to a review workflow and
-- measure confirmed fraud separately from suspected cases.
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN LOWER(order_status) LIKE '%suspected%fraud%' THEN 1 ELSE 0 END)
        AS suspected_fraud_rows,
    COUNT(DISTINCT CASE
        WHEN LOWER(order_status) LIKE '%suspected%fraud%' THEN order_id
    END) AS suspected_fraud_orders,
    ROUND(
        100.0 * SUM(CASE WHEN LOWER(order_status) LIKE '%suspected%fraud%' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS suspected_fraud_row_pct
FROM supply_chain_orders;


-- Q22. How are suspected-fraud records distributed by payment type?
-- Business Question: Which payment types have the most suspected-fraud records?
-- Business Insight: Counts show volume, but a popular payment method may have
-- more flagged records simply because it is used more often.
-- Business Recommendation: Compare fraud rate within each payment type, not
-- only raw counts, before changing authentication or payment controls.
SELECT
    payment_type,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN LOWER(order_status) LIKE '%suspected%fraud%' THEN 1 ELSE 0 END)
        AS suspected_fraud_rows,
    ROUND(
        100.0 * SUM(CASE WHEN LOWER(order_status) LIKE '%suspected%fraud%' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS suspected_fraud_rate_pct
FROM supply_chain_orders
GROUP BY payment_type
ORDER BY suspected_fraud_rate_pct DESC;


-- Q23. Which markets have the most suspected-fraud records?
-- Business Question: Where are suspected-fraud records concentrated?
-- Business Insight: Helps locate concentrations for further investigation.
-- Business Recommendation: Combine fraud rate, order volume, and confirmed loss
-- data before prioritizing market-specific controls.
SELECT
    market,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN LOWER(order_status) LIKE '%suspected%fraud%' THEN 1 ELSE 0 END)
        AS suspected_fraud_rows,
    ROUND(
        100.0 * SUM(CASE WHEN LOWER(order_status) LIKE '%suspected%fraud%' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS suspected_fraud_rate_pct
FROM supply_chain_orders
GROUP BY market
ORDER BY suspected_fraud_rate_pct DESC;


/*
===============================================================================
SECTION 7 — TIME TRENDS & SEASONALITY
===============================================================================
*/

-- Q24. What is the monthly sales trend?
-- Business Question: How does sales change over time?
-- Business Insight: Reveals month-to-month movement and potential seasonal
-- patterns; the source report describes recurring Q4 peaks.
-- Business Recommendation: Use validated seasonal patterns to plan inventory,
-- staffing, and carrier capacity in advance of peak months.
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    DATE_FORMAT(order_date, '%Y-%m') AS year_month,
    ROUND(SUM(sales), 2) AS monthly_sales,
    ROUND(SUM(profit_per_order), 2) AS monthly_profit
FROM supply_chain_orders
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date), DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_year, order_month;


-- Q25. How do sales and profit compare by quarter and year?
-- Business Question: Is quarterly performance consistent across years?
-- Business Insight: Tests whether Q4 or another quarter repeatedly leads sales
-- and profit instead of relying on a single year's result.
-- Business Recommendation: Build a seasonal readiness plan only after checking
-- each complete year and accounting for incomplete periods in the dataset.
SELECT
    YEAR(order_date) AS order_year,
    QUARTER(order_date) AS order_quarter,
    ROUND(SUM(sales), 2) AS quarterly_sales,
    ROUND(SUM(profit_per_order), 2) AS quarterly_profit,
    ROUND(100.0 * SUM(profit_per_order) / NULLIF(SUM(sales), 0), 2)
        AS quarterly_margin_pct
FROM supply_chain_orders
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), QUARTER(order_date)
ORDER BY order_year, order_quarter;


-- Q26. Which months have the weakest profit?
-- Business Question: When does profitability deteriorate?
-- Business Insight: Identifies periods requiring a closer look at discounts,
-- product mix, shipping costs, or demand patterns.
-- Business Recommendation: Review the drivers behind low-profit months before
-- changing promotions or budgets.
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    DATE_FORMAT(order_date, '%Y-%m') AS year_month,
    ROUND(SUM(sales), 2) AS monthly_sales,
    ROUND(SUM(profit_per_order), 2) AS monthly_profit,
    ROUND(100.0 * SUM(profit_per_order) / NULLIF(SUM(sales), 0), 2)
        AS profit_margin_pct
FROM supply_chain_orders
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date), DATE_FORMAT(order_date, '%Y-%m')
ORDER BY monthly_profit ASC
LIMIT 12;


/*
===============================================================================
SECTION 8 — CUSTOMER & ORDER ANALYSIS
===============================================================================
*/

-- Q27. How many orders does each customer place on average?
-- Business Question: What is the average number of distinct orders per customer?
-- Business Insight: Gives a simple repeat-order baseline, but does not explain
-- retention timing or customer lifetime value.
-- Business Recommendation: Segment one-time and repeat customers, then test
-- appropriate retention campaigns using reliable contact data and consent.
SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(
        COUNT(DISTINCT order_id) / NULLIF(COUNT(DISTINCT customer_id), 0), 2
    ) AS orders_per_customer
FROM supply_chain_orders;


-- Q28. Which customers have the highest sales contribution?
-- Business Question: Which customers contribute the most sales?
-- Business Insight: Shows customer-level concentration and can identify accounts
-- whose purchasing activity has a material impact on revenue.
-- Business Recommendation: Review account retention and service needs for
-- leading customers while avoiding over-reliance on a small number of accounts.
SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit_per_order), 2) AS total_profit
FROM supply_chain_orders
GROUP BY customer_id
ORDER BY total_sales DESC
LIMIT 20;


-- Q29. What is the order-status mix by customer segment?
-- Business Question: Do processing outcomes differ across customer segments?
-- Business Insight: Segment-level status patterns can help locate differences
-- in payment or fulfilment experience.
-- Business Recommendation: Investigate material differences with operations and
-- customer-service teams before designing segment-specific interventions.
SELECT
    customer_segment,
    order_status,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM supply_chain_orders
GROUP BY customer_segment, order_status
ORDER BY customer_segment, item_rows DESC;


/*
===============================================================================
SECTION 9 — DATA QUALITY & VALIDATION
===============================================================================
*/

-- Q30. Which important columns contain missing values?
-- Business Question: Are key analysis fields incomplete?
-- Business Insight: Missing dates, dimensions, or measures can distort trends
-- and KPI calculations.
-- Business Recommendation: Add repeatable data-quality checks to the pipeline
-- and document any exclusions or imputation rules.
SELECT
    SUM(order_date IS NULL) AS missing_order_dates,
    SUM(shipping_date IS NULL) AS missing_shipping_dates,
    SUM(market IS NULL OR TRIM(market) = '') AS missing_market,
    SUM(customer_segment IS NULL OR TRIM(customer_segment) = '') AS missing_segment,
    SUM(sales IS NULL) AS missing_sales,
    SUM(profit_per_order IS NULL) AS missing_profit,
    SUM(discount_rate IS NULL) AS missing_discount_rate
FROM supply_chain_orders;


-- Q31. Are there duplicate order-item identifiers?
-- Business Question: Does order_item_id uniquely identify rows?
-- Business Insight: Duplicate identifiers can inflate sums and counts if they
-- represent accidental duplicate records.
-- Business Recommendation: Investigate duplicate keys before removing anything;
-- confirm whether repeats are genuine source records or import issues.
SELECT
    order_item_id,
    COUNT(*) AS occurrences
FROM supply_chain_orders
GROUP BY order_item_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- Q32. Are there records with invalid or inconsistent shipping durations?
-- Business Question: Do actual and scheduled shipping durations contain
-- implausible values?
-- Business Insight: Negative or null durations may signal source-data or
-- transformation issues and can affect delivery-delay analysis.
-- Business Recommendation: Validate flagged records against source definitions
-- before correcting or excluding them.
SELECT
    COUNT(*) AS total_rows,
    SUM(actual_shipping_days IS NULL) AS null_actual_days,
    SUM(scheduled_shipping_days IS NULL) AS null_scheduled_days,
    SUM(actual_shipping_days < 0) AS negative_actual_days,
    SUM(scheduled_shipping_days < 0) AS negative_scheduled_days
FROM supply_chain_orders;


/*
===============================================================================
SECTION 10 — EXECUTIVE KPI SUMMARY
===============================================================================
*/

-- Q33. What is the current executive KPI snapshot?
-- Business Question: What are the key operational and financial indicators in
-- one result row?
-- Business Insight: Consolidates revenue, profit, margin, delivery, and fraud
-- measures into a compact management view.
-- Business Recommendation: Publish this result only after validating row grain,
-- status definitions, and the denominator used for each KPI.
SELECT
    COUNT(*) AS total_item_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit_per_order), 2) AS total_profit,
    ROUND(100.0 * SUM(profit_per_order) / NULLIF(SUM(sales), 0), 2)
        AS profit_margin_pct,
    ROUND(
        100.0 * SUM(CASE WHEN LOWER(delivery_status) LIKE '%late%' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS late_delivery_row_pct,
    ROUND(AVG(actual_shipping_days), 2) AS avg_actual_shipping_days,
    ROUND(
        100.0 * SUM(CASE WHEN LOWER(order_status) LIKE '%suspected%fraud%' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS suspected_fraud_row_pct
FROM supply_chain_orders;


/*
===============================================================================
FINAL BUSINESS RECOMMENDATIONS
===============================================================================

1. DELIVERY PERFORMANCE
   - Break down late-delivery rate by shipping mode, market, and region.
   - Investigate high-volume/high-delay combinations first.
   - Compare actual shipping duration with the scheduled promise.
   - Track delivery KPIs weekly and define a realistic improvement target.

2. PROFITABILITY & DISCOUNT GOVERNANCE
   - Review products and categories with negative aggregate profit or weak margin.
   - Compare discount bands with profit and sales volume.
   - Use approval thresholds as a pilot and measure the effect before broad rollout.
   - Avoid assuming discounting caused losses without controlling for product mix
     and other factors.

3. FRAUD-RISK REVIEW
   - Treat Suspected_Fraud as a flag for investigation, not confirmed fraud.
   - Compare rates by payment type and market, not just raw counts.
   - Track confirmed fraud and actual financial loss separately.
   - Apply additional controls only after validating false positives and risk rates.

4. INVENTORY & SEASONAL PLANNING
   - Validate recurring quarterly/monthly patterns across complete years.
   - Forecast demand before setting safety stock or carrier-capacity commitments.
   - Review leading products for stockout and supplier-concentration risk.

5. CUSTOMER & SEGMENT STRATEGY
   - Compare both total contribution and average economics by segment.
   - Examine repeat-order behaviour and customer concentration.
   - Test segment-specific initiatives and measure incremental outcomes.

6. DATA GOVERNANCE
   - Validate key uniqueness, missing values, date fields, and row grain.
   - Document data-cleaning rules and KPI denominators.
   - Keep sensitive or placeholder fields out of analytical exports.
   - Reconcile metrics between SQL, Python, and dashboards before publishing.

PORTFOLIO DISCLAIMER
The insights and recommendations above are analysis prompts grounded in the
project report. Re-run the SQL on the final cleaned table and verify all reported
values before describing them as confirmed business outcomes.
===============================================================================
