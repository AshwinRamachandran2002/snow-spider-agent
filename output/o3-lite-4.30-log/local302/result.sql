WITH period_sales AS (
    SELECT
        week_date,
        region,
        platform,
        age_band,
        demographic,
        customer_type,
        sales,
        CASE
            WHEN week_date BETWEEN '2020-03-23' AND '2020-06-14' THEN 'pre'
            WHEN week_date BETWEEN '2020-06-15' AND '2020-09-06' THEN 'post'
        END AS period
    FROM cleaned_weekly_sales
    WHERE week_date BETWEEN '2020-03-23' AND '2020-09-06'
),
-- percentage change for each value of every attribute ------------
region_change AS (
    SELECT
        'region' AS attribute_type,
        100.0 * (SUM(CASE WHEN period = 'post' THEN sales END) -
                 SUM(CASE WHEN period = 'pre'  THEN sales END)) /
                 SUM(CASE WHEN period = 'pre'  THEN sales END) AS pct_change
    FROM period_sales
    GROUP BY region
),
platform_change AS (
    SELECT
        'platform' AS attribute_type,
        100.0 * (SUM(CASE WHEN period = 'post' THEN sales END) -
                 SUM(CASE WHEN period = 'pre'  THEN sales END)) /
                 SUM(CASE WHEN period = 'pre'  THEN sales END) AS pct_change
    FROM period_sales
    GROUP BY platform
),
age_band_change AS (
    SELECT
        'age_band' AS attribute_type,
        100.0 * (SUM(CASE WHEN period = 'post' THEN sales END) -
                 SUM(CASE WHEN period = 'pre'  THEN sales END)) /
                 SUM(CASE WHEN period = 'pre'  THEN sales END) AS pct_change
    FROM period_sales
    GROUP BY age_band
),
demographic_change AS (
    SELECT
        'demographic' AS attribute_type,
        100.0 * (SUM(CASE WHEN period = 'post' THEN sales END) -
                 SUM(CASE WHEN period = 'pre'  THEN sales END)) /
                 SUM(CASE WHEN period = 'pre'  THEN sales END) AS pct_change
    FROM period_sales
    GROUP BY demographic
),
customer_type_change AS (
    SELECT
        'customer_type' AS attribute_type,
        100.0 * (SUM(CASE WHEN period = 'post' THEN sales END) -
                 SUM(CASE WHEN period = 'pre'  THEN sales END)) /
                 SUM(CASE WHEN period = 'pre'  THEN sales END) AS pct_change
    FROM period_sales
    GROUP BY customer_type
),
-- average percentage change for each attribute -------------------
avg_changes AS (
    SELECT attribute_type,
           AVG(pct_change) AS average_percentage_change
    FROM (
        SELECT * FROM region_change
        UNION ALL
        SELECT * FROM platform_change
        UNION ALL
        SELECT * FROM age_band_change
        UNION ALL
        SELECT * FROM demographic_change
        UNION ALL
        SELECT * FROM customer_type_change
    )
    GROUP BY attribute_type
)
-- attribute with the largest negative impact ---------------------
SELECT
    attribute_type,
    ROUND(average_percentage_change, 4) AS average_percentage_change
FROM avg_changes
ORDER BY average_percentage_change ASC
LIMIT 1;