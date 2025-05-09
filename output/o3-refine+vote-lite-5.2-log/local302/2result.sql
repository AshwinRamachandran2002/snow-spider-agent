WITH
-- 1.  Region level before / after totals
region_sales AS (
    SELECT COALESCE(region,'unknown')           AS val,
           SUM(CASE WHEN week_date BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END) AS before_sales,
           SUM(CASE WHEN week_date BETWEEN '2020-06-16' AND '2020-09-07' THEN sales END) AS after_sales
    FROM   cleaned_weekly_sales
    WHERE  week_date BETWEEN '2020-03-23' AND '2020-09-07'
    GROUP  BY COALESCE(region,'unknown')
),
-- 2.  Platform level
platform_sales AS (
    SELECT COALESCE(platform,'unknown')         AS val,
           SUM(CASE WHEN week_date BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END) AS before_sales,
           SUM(CASE WHEN week_date BETWEEN '2020-06-16' AND '2020-09-07' THEN sales END) AS after_sales
    FROM   cleaned_weekly_sales
    WHERE  week_date BETWEEN '2020-03-23' AND '2020-09-07'
    GROUP  BY COALESCE(platform,'unknown')
),
-- 3.  Age‑band level
age_band_sales AS (
    SELECT COALESCE(age_band,'unknown')         AS val,
           SUM(CASE WHEN week_date BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END) AS before_sales,
           SUM(CASE WHEN week_date BETWEEN '2020-06-16' AND '2020-09-07' THEN sales END) AS after_sales
    FROM   cleaned_weekly_sales
    WHERE  week_date BETWEEN '2020-03-23' AND '2020-09-07'
    GROUP  BY COALESCE(age_band,'unknown')
),
-- 4.  Demographic level
demo_sales AS (
    SELECT COALESCE(demographic,'unknown')      AS val,
           SUM(CASE WHEN week_date BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END) AS before_sales,
           SUM(CASE WHEN week_date BETWEEN '2020-06-16' AND '2020-09-07' THEN sales END) AS after_sales
    FROM   cleaned_weekly_sales
    WHERE  week_date BETWEEN '2020-03-23' AND '2020-09-07'
    GROUP  BY COALESCE(demographic,'unknown')
),
-- 5.  Customer‑type level
cust_type_sales AS (
    SELECT COALESCE(customer_type,'unknown')    AS val,
           SUM(CASE WHEN week_date BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END) AS before_sales,
           SUM(CASE WHEN week_date BETWEEN '2020-06-16' AND '2020-09-07' THEN sales END) AS after_sales
    FROM   cleaned_weekly_sales
    WHERE  week_date BETWEEN '2020-03-23' AND '2020-09-07'
    GROUP  BY COALESCE(customer_type,'unknown')
),
-- 6.  Average % change for every attribute type
averages AS (
    SELECT 'region'        AS attribute_type,
           AVG( (after_sales - before_sales) * 100.0 / before_sales ) AS avg_pct_change
    FROM   region_sales
    WHERE  before_sales > 0

    UNION ALL
    SELECT 'platform',
           AVG( (after_sales - before_sales) * 100.0 / before_sales )
    FROM   platform_sales
    WHERE  before_sales > 0

    UNION ALL
    SELECT 'age_band',
           AVG( (after_sales - before_sales) * 100.0 / before_sales )
    FROM   age_band_sales
    WHERE  before_sales > 0

    UNION ALL
    SELECT 'demographic',
           AVG( (after_sales - before_sales) * 100.0 / before_sales )
    FROM   demo_sales
    WHERE  before_sales > 0

    UNION ALL
    SELECT 'customer_type',
           AVG( (after_sales - before_sales) * 100.0 / before_sales )
    FROM   cust_type_sales
    WHERE  before_sales > 0
)
SELECT  attribute_type,
        ROUND(avg_pct_change,4) AS avg_pct_change,
        CASE WHEN avg_pct_change = (SELECT MIN(avg_pct_change) FROM averages)
             THEN 'highest negative impact' END AS impact_flag
FROM    averages
ORDER BY avg_pct_change;