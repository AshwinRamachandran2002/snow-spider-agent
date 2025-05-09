WITH period_sales AS (           -- classify each week into the 12‑week “before” and “after” windows
    SELECT
        date("week_date")                 AS week_dt,
        "region",
        "platform",
        "age_band",
        "demographic",
        "customer_type",
        "sales",
        CASE
            WHEN date("week_date") BETWEEN date('2020-06-15','-84 day') AND date('2020-06-15','-7 day')  THEN 'before'
            WHEN date("week_date") BETWEEN date('2020-06-15')            AND date('2020-06-15','+77 day') THEN 'after'
        END AS period
    FROM "cleaned_weekly_sales"
    WHERE date("week_date") BETWEEN date('2020-06-15','-84 day') AND date('2020-06-15','+77 day')
),

/* -------- percentage‑change of sales for every value of every attribute -------- */
region_changes AS (
    SELECT 'region' AS attribute_type,
           region   AS attribute_value,
           (after_sales - before_sales) * 100.0 / before_sales AS pct_change
    FROM (
        SELECT region,
               SUM(CASE WHEN period='before' THEN sales END) AS before_sales,
               SUM(CASE WHEN period='after'  THEN sales END) AS after_sales
        FROM period_sales
        GROUP BY region
    )
    WHERE before_sales > 0
),
platform_changes AS (
    SELECT 'platform', platform,
           (after_sales - before_sales) * 100.0 / before_sales
    FROM (
        SELECT platform,
               SUM(CASE WHEN period='before' THEN sales END) AS before_sales,
               SUM(CASE WHEN period='after'  THEN sales END) AS after_sales
        FROM period_sales
        GROUP BY platform
    )
    WHERE before_sales > 0
),
age_band_changes AS (
    SELECT 'age_band', age_band,
           (after_sales - before_sales) * 100.0 / before_sales
    FROM (
        SELECT age_band,
               SUM(CASE WHEN period='before' THEN sales END) AS before_sales,
               SUM(CASE WHEN period='after'  THEN sales END) AS after_sales
        FROM period_sales
        GROUP BY age_band
    )
    WHERE before_sales > 0
),
demographic_changes AS (
    SELECT 'demographic', demographic,
           (after_sales - before_sales) * 100.0 / before_sales
    FROM (
        SELECT demographic,
               SUM(CASE WHEN period='before' THEN sales END) AS before_sales,
               SUM(CASE WHEN period='after'  THEN sales END) AS after_sales
        FROM period_sales
        GROUP BY demographic
    )
    WHERE before_sales > 0
),
customer_type_changes AS (
    SELECT 'customer_type', customer_type,
           (after_sales - before_sales) * 100.0 / before_sales
    FROM (
        SELECT customer_type,
               SUM(CASE WHEN period='before' THEN sales END) AS before_sales,
               SUM(CASE WHEN period='after'  THEN sales END) AS after_sales
        FROM period_sales
        GROUP BY customer_type
    )
    WHERE before_sales > 0
),

/* -------- gather all % changes together -------- */
all_changes AS (
    SELECT * FROM region_changes
    UNION ALL
    SELECT * FROM platform_changes
    UNION ALL
    SELECT * FROM age_band_changes
    UNION ALL
    SELECT * FROM demographic_changes
    UNION ALL
    SELECT * FROM customer_type_changes
),

/* -------- average % change for each attribute type -------- */
attribute_averages AS (
    SELECT
        attribute_type,
        AVG(pct_change) AS avg_pct_change
    FROM all_changes
    GROUP BY attribute_type
)

/* -------- attribute type with the largest negative impact -------- */
SELECT
    attribute_type,
    avg_pct_change
FROM attribute_averages
ORDER BY avg_pct_change ASC      -- most negative first
LIMIT 1;