WITH windowed AS (
    SELECT
        region,
        platform,
        age_band,
        demographic,
        customer_type,
        sales,
        CASE
            WHEN week_date < '2020-06-15' THEN 'before'
            WHEN week_date BETWEEN '2020-06-15' AND '2020-08-31' THEN 'after'
        END AS period
    FROM cleaned_weekly_sales
    WHERE week_date BETWEEN '2020-03-23' AND '2020-08-31'
),
agg_per_value AS (
    SELECT region AS attribute_value, 'region' AS attribute_type,
           SUM(CASE WHEN period='before' THEN sales END) AS sales_before,
           SUM(CASE WHEN period='after'  THEN sales END) AS sales_after
    FROM windowed WHERE period IS NOT NULL GROUP BY region
    UNION ALL
    SELECT platform, 'platform',
           SUM(CASE WHEN period='before' THEN sales END),
           SUM(CASE WHEN period='after'  THEN sales END)
    FROM windowed WHERE period IS NOT NULL GROUP BY platform
    UNION ALL
    SELECT age_band, 'age_band',
           SUM(CASE WHEN period='before' THEN sales END),
           SUM(CASE WHEN period='after'  THEN sales END)
    FROM windowed WHERE period IS NOT NULL GROUP BY age_band
    UNION ALL
    SELECT demographic, 'demographic',
           SUM(CASE WHEN period='before' THEN sales END),
           SUM(CASE WHEN period='after'  THEN sales END)
    FROM windowed WHERE period IS NOT NULL GROUP BY demographic
    UNION ALL
    SELECT customer_type, 'customer_type',
           SUM(CASE WHEN period='before' THEN sales END),
           SUM(CASE WHEN period='after'  THEN sales END)
    FROM windowed WHERE period IS NOT NULL GROUP BY customer_type
),
pct_change AS (
    SELECT
        attribute_type,
        (sales_after - sales_before) * 1.0 / NULLIF(sales_before,0) AS pct_change
    FROM agg_per_value
    WHERE sales_before IS NOT NULL
),
avg_change AS (
    SELECT
        attribute_type,
        AVG(pct_change) AS average_percentage_change
    FROM pct_change
    GROUP BY attribute_type
)
SELECT attribute_type,
       ROUND(average_percentage_change,4) AS average_percentage_change
FROM avg_change
ORDER BY average_percentage_change
LIMIT 1;