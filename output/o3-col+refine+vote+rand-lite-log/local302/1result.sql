/*  Average percentage sales change (POST 15-Jun-2020 window vs PRE window)
    for every attribute type and ordered so the largest negative effect
    (smallest average pct-change) appears first                          */

WITH
-- ---------- region ----------
region_stats AS (
  SELECT region,
         SUM(CASE WHEN week_date BETWEEN '2020-03-23' AND '2020-06-07' THEN sales END)  AS pre_sales,
         SUM(CASE WHEN week_date BETWEEN '2020-06-15' AND '2020-08-31' THEN sales END)  AS post_sales
  FROM cleaned_weekly_sales
  WHERE week_date BETWEEN '2020-03-23' AND '2020-08-31'
  GROUP BY region
),
region_pct AS (
  SELECT 'region' AS attribute_type,
         100.0 * (post_sales - pre_sales) / NULLIF(pre_sales,0) AS pct_change
  FROM region_stats
),

-- ---------- platform ----------
platform_stats AS (
  SELECT platform,
         SUM(CASE WHEN week_date BETWEEN '2020-03-23' AND '2020-06-07' THEN sales END)  AS pre_sales,
         SUM(CASE WHEN week_date BETWEEN '2020-06-15' AND '2020-08-31' THEN sales END)  AS post_sales
  FROM cleaned_weekly_sales
  WHERE week_date BETWEEN '2020-03-23' AND '2020-08-31'
  GROUP BY platform
),
platform_pct AS (
  SELECT 'platform' AS attribute_type,
         100.0 * (post_sales - pre_sales) / NULLIF(pre_sales,0) AS pct_change
  FROM platform_stats
),

-- ---------- age band ----------
age_stats AS (
  SELECT age_band,
         SUM(CASE WHEN week_date BETWEEN '2020-03-23' AND '2020-06-07' THEN sales END)  AS pre_sales,
         SUM(CASE WHEN week_date BETWEEN '2020-06-15' AND '2020-08-31' THEN sales END)  AS post_sales
  FROM cleaned_weekly_sales
  WHERE week_date BETWEEN '2020-03-23' AND '2020-08-31'
  GROUP BY age_band
),
age_pct AS (
  SELECT 'age_band' AS attribute_type,
         100.0 * (post_sales - pre_sales) / NULLIF(pre_sales,0) AS pct_change
  FROM age_stats
),

-- ---------- demographic ----------
demo_stats AS (
  SELECT demographic,
         SUM(CASE WHEN week_date BETWEEN '2020-03-23' AND '2020-06-07' THEN sales END)  AS pre_sales,
         SUM(CASE WHEN week_date BETWEEN '2020-06-15' AND '2020-08-31' THEN sales END)  AS post_sales
  FROM cleaned_weekly_sales
  WHERE week_date BETWEEN '2020-03-23' AND '2020-08-31'
  GROUP BY demographic
),
demo_pct AS (
  SELECT 'demographic' AS attribute_type,
         100.0 * (post_sales - pre_sales) / NULLIF(pre_sales,0) AS pct_change
  FROM demo_stats
),

-- ---------- customer type ----------
cust_stats AS (
  SELECT customer_type,
         SUM(CASE WHEN week_date BETWEEN '2020-03-23' AND '2020-06-07' THEN sales END)  AS pre_sales,
         SUM(CASE WHEN week_date BETWEEN '2020-06-15' AND '2020-08-31' THEN sales END)  AS post_sales
  FROM cleaned_weekly_sales
  WHERE week_date BETWEEN '2020-03-23' AND '2020-08-31'
  GROUP BY customer_type
),
cust_pct AS (
  SELECT 'customer_type' AS attribute_type,
         100.0 * (post_sales - pre_sales) / NULLIF(pre_sales,0) AS pct_change
  FROM cust_stats
),

-- ---------- consolidate ----------
all_pct AS (
  SELECT * FROM region_pct
  UNION ALL
  SELECT * FROM platform_pct
  UNION ALL
  SELECT * FROM age_pct
  UNION ALL
  SELECT * FROM demo_pct
  UNION ALL
  SELECT * FROM cust_pct
)

SELECT
  attribute_type,
  ROUND(AVG(pct_change), 2) AS avg_pct_change
FROM all_pct
GROUP BY attribute_type
ORDER BY avg_pct_change;        -- first row = greatest negative impact