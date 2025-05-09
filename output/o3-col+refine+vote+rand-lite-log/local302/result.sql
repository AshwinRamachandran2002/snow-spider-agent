WITH period_sales AS (   -- total sales in the 12 wks BEFORE & AFTER 15-Jun-2020
    SELECT 'before' AS period,
           region, platform, age_band, demographic, customer_type,
           SUM(sales) AS sales
    FROM   cleaned_weekly_sales
    WHERE  week_date BETWEEN '2020-03-23' AND '2020-06-08'
    GROUP  BY region, platform, age_band, demographic, customer_type

    UNION ALL

    SELECT 'after',
           region, platform, age_band, demographic, customer_type,
           SUM(sales)
    FROM   cleaned_weekly_sales
    WHERE  week_date BETWEEN '2020-06-15' AND '2020-09-07'
    GROUP  BY region, platform, age_band, demographic, customer_type
),

/* % change for each value of every requested attribute ------------------- */
region_pct AS (
    SELECT region AS attr_val,
           (SUM(CASE WHEN period='after'  THEN sales END) -
            SUM(CASE WHEN period='before' THEN sales END))*1.0
            / SUM(CASE WHEN period='before' THEN sales END) * 100  AS pct
    FROM   period_sales
    GROUP  BY region
    HAVING SUM(CASE WHEN period='before' THEN sales END) > 0
),
platform_pct AS (
    SELECT platform AS attr_val,
           (SUM(CASE WHEN period='after'  THEN sales END) -
            SUM(CASE WHEN period='before' THEN sales END))*1.0
            / SUM(CASE WHEN period='before' THEN sales END) * 100  AS pct
    FROM   period_sales
    GROUP  BY platform
    HAVING SUM(CASE WHEN period='before' THEN sales END) > 0
),
age_band_pct AS (
    SELECT age_band AS attr_val,
           (SUM(CASE WHEN period='after'  THEN sales END) -
            SUM(CASE WHEN period='before' THEN sales END))*1.0
            / SUM(CASE WHEN period='before' THEN sales END) * 100  AS pct
    FROM   period_sales
    GROUP  BY age_band
    HAVING SUM(CASE WHEN period='before' THEN sales END) > 0
),
demographic_pct AS (
    SELECT demographic AS attr_val,
           (SUM(CASE WHEN period='after'  THEN sales END) -
            SUM(CASE WHEN period='before' THEN sales END))*1.0
            / SUM(CASE WHEN period='before' THEN sales END) * 100  AS pct
    FROM   period_sales
    GROUP  BY demographic
    HAVING SUM(CASE WHEN period='before' THEN sales END) > 0
),
customer_type_pct AS (
    SELECT customer_type AS attr_val,
           (SUM(CASE WHEN period='after'  THEN sales END) -
            SUM(CASE WHEN period='before' THEN sales END))*1.0
            / SUM(CASE WHEN period='before' THEN sales END) * 100  AS pct
    FROM   period_sales
    GROUP  BY customer_type
    HAVING SUM(CASE WHEN period='before' THEN sales END) > 0
),

/* average % change for each attribute type -------------------------------- */
avg_changes AS (
    SELECT 'region'        AS attribute_type, ROUND(AVG(pct),4) AS avg_pct_change FROM region_pct
    UNION ALL
    SELECT 'platform',      ROUND(AVG(pct),4)                   FROM platform_pct
    UNION ALL
    SELECT 'age_band',      ROUND(AVG(pct),4)                   FROM age_band_pct
    UNION ALL
    SELECT 'demographic',   ROUND(AVG(pct),4)                   FROM demographic_pct
    UNION ALL
    SELECT 'customer_type', ROUND(AVG(pct),4)                   FROM customer_type_pct
)

/* attribute type with the highest negative (most detrimental) change ------ */
SELECT attribute_type,
       avg_pct_change
FROM   avg_changes
ORDER  BY avg_pct_change    -- lowest (most negative) first
LIMIT  1;