WITH
-- 12 weeks before 15-Jun-2020
before AS (
    SELECT region, platform, age_band, demographic, customer_type, sales
    FROM cleaned_weekly_sales
    WHERE week_date >= '2020-03-23'
      AND week_date  < '2020-06-15'
),
-- 12 weeks after (incl. pivot week)
after  AS (
    SELECT region, platform, age_band, demographic, customer_type, sales
    FROM cleaned_weekly_sales
    WHERE week_date >= '2020-06-15'
      AND week_date <= '2020-08-31'
),
-- total sales for every attribute value in each period
before_sum AS (
    SELECT 'region'        AS attribute_type, region        AS attribute_value, SUM(sales) AS sales_before FROM before GROUP BY region
    UNION ALL
    SELECT 'platform',      platform,      SUM(sales) FROM before GROUP BY platform
    UNION ALL
    SELECT 'age_band',      age_band,      SUM(sales) FROM before GROUP BY age_band
    UNION ALL
    SELECT 'demographic',   demographic,   SUM(sales) FROM before GROUP BY demographic
    UNION ALL
    SELECT 'customer_type', customer_type, SUM(sales) FROM before GROUP BY customer_type
),
after_sum AS (
    SELECT 'region'        AS attribute_type, region        AS attribute_value, SUM(sales) AS sales_after FROM after GROUP BY region
    UNION ALL
    SELECT 'platform',      platform,      SUM(sales) FROM after GROUP BY platform
    UNION ALL
    SELECT 'age_band',      age_band,      SUM(sales) FROM after GROUP BY age_band
    UNION ALL
    SELECT 'demographic',   demographic,   SUM(sales) FROM after GROUP BY demographic
    UNION ALL
    SELECT 'customer_type', customer_type, SUM(sales) FROM after GROUP BY customer_type
),
-- % change for every individual attribute value
changes AS (
    SELECT b.attribute_type,
           100.0 * (a.sales_after - b.sales_before) / b.sales_before AS pct_change
    FROM   before_sum b
    JOIN   after_sum  a
      ON   a.attribute_type = b.attribute_type
     AND   a.attribute_value = b.attribute_value
),
-- average % change for each attribute type
avg_changes AS (
    SELECT attribute_type,
           ROUND(AVG(pct_change),4) AS avg_pct_change
    FROM   changes
    GROUP  BY attribute_type
)
-- attribute type with the largest negative impact
SELECT attribute_type,
       avg_pct_change
FROM   avg_changes
ORDER  BY avg_pct_change      -- most negative first
LIMIT 1;