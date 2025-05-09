/* 12‑week windows are defined with ISO week 25 (15‑Jun‑2020) as the split.
   Weeks 13‑24  → “before”, 26‑37 → “after”                                        */
WITH period_sales AS (
    SELECT
        region,
        platform,
        age_band,
        demographic,
        customer_type,
        sales,
        CASE
            WHEN calendar_year = 2020 AND week_number BETWEEN 13 AND 24 THEN 'before'
            WHEN calendar_year = 2020 AND week_number BETWEEN 26 AND 37 THEN 'after'
        END AS period
    FROM cleaned_weekly_sales
    WHERE calendar_year = 2020
      AND week_number BETWEEN 13 AND 37          -- restrict to the two 12‑week windows
),
/* put each attribute in the same column                                         */
unpivot AS (
    SELECT 'region'        AS attribute_type, region        AS attribute_value, period, sales FROM period_sales
    UNION ALL
    SELECT 'platform',      platform,      period, sales FROM period_sales
    UNION ALL
    SELECT 'age_band',      age_band,      period, sales FROM period_sales
    UNION ALL
    SELECT 'demographic',   demographic,   period, sales FROM period_sales
    UNION ALL
    SELECT 'customer_type', customer_type, period, sales FROM period_sales
),
/* total sales by attribute value & period                                       */
value_period_totals AS (
    SELECT
        attribute_type,
        attribute_value,
        period,
        SUM(sales) AS total_sales
    FROM unpivot
    WHERE period IS NOT NULL
      AND attribute_value IS NOT NULL
    GROUP BY attribute_type, attribute_value, period
),
/* before vs after totals per value                                              */
value_changes AS (
    SELECT
        attribute_type,
        attribute_value,
        SUM(CASE WHEN period = 'before' THEN total_sales END) AS sales_before,
        SUM(CASE WHEN period = 'after'  THEN total_sales END) AS sales_after
    FROM value_period_totals
    GROUP BY attribute_type, attribute_value
),
/* % change for every value                                                      */
value_pct_change AS (
    SELECT
        attribute_type,
        attribute_value,
        (sales_after - sales_before) * 100.0 / sales_before AS pct_change
    FROM value_changes
    WHERE sales_before > 0
),
/* average % change across values for each attribute type                        */
avg_pct_change AS (
    SELECT
        attribute_type,
        AVG(pct_change) AS avg_pct_change
    FROM value_pct_change
    GROUP BY attribute_type
)
/* attribute type with the greatest negative impact                              */
SELECT
    attribute_type,
    ROUND(avg_pct_change,4) AS avg_percentage_change
FROM avg_pct_change
ORDER BY avg_pct_change ASC
LIMIT 1;