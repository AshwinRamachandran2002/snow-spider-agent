/* Average % change in sales for each attribute type and flag the
   one with the largest (most-negative) fall in sales               */
WITH date_window AS (
    SELECT
        '2020-03-23' AS before_start , '2020-06-14' AS before_end ,
        '2020-06-15' AS  after_start , '2020-09-06' AS  after_end
),

/* ---- 1. %-change for every value inside each attribute type ---- */
region_vals AS (
    SELECT region AS attr_val,
           SUM(CASE WHEN week_date BETWEEN before_start AND before_end THEN sales END) AS before_sales,
           SUM(CASE WHEN week_date BETWEEN after_start  AND after_end  THEN sales END) AS after_sales
    FROM cleaned_weekly_sales, date_window
    WHERE calendar_year = 2020
    GROUP BY region
),
platform_vals AS (
    SELECT platform AS attr_val,
           SUM(CASE WHEN week_date BETWEEN before_start AND before_end THEN sales END) AS before_sales,
           SUM(CASE WHEN week_date BETWEEN after_start  AND after_end  THEN sales END) AS after_sales
    FROM cleaned_weekly_sales, date_window
    WHERE calendar_year = 2020
    GROUP BY platform
),
ageband_vals AS (
    SELECT age_band AS attr_val,
           SUM(CASE WHEN week_date BETWEEN before_start AND before_end THEN sales END) AS before_sales,
           SUM(CASE WHEN week_date BETWEEN after_start  AND after_end  THEN sales END) AS after_sales
    FROM cleaned_weekly_sales, date_window
    WHERE calendar_year = 2020
    GROUP BY age_band
),
demo_vals AS (
    SELECT demographic AS attr_val,
           SUM(CASE WHEN week_date BETWEEN before_start AND before_end THEN sales END) AS before_sales,
           SUM(CASE WHEN week_date BETWEEN after_start  AND after_end  THEN sales END) AS after_sales
    FROM cleaned_weekly_sales, date_window
    WHERE calendar_year = 2020
    GROUP BY demographic
),
custtype_vals AS (
    SELECT customer_type AS attr_val,
           SUM(CASE WHEN week_date BETWEEN before_start AND before_end THEN sales END) AS before_sales,
           SUM(CASE WHEN week_date BETWEEN after_start  AND after_end  THEN sales END) AS after_sales
    FROM cleaned_weekly_sales, date_window
    WHERE calendar_year = 2020
    GROUP BY customer_type
),

/* ---- 2.  Average %-change across the values of each attribute ---- */
avg_changes AS (
    SELECT 'region'        AS attribute_type,
           ROUND(AVG((after_sales - before_sales) * 100.0 / before_sales),4) AS avg_pct_change
    FROM region_vals

    UNION ALL
    SELECT 'platform',
           ROUND(AVG((after_sales - before_sales) * 100.0 / before_sales),4)
    FROM platform_vals

    UNION ALL
    SELECT 'age_band',
           ROUND(AVG((after_sales - before_sales) * 100.0 / before_sales),4)
    FROM ageband_vals

    UNION ALL
    SELECT 'demographic',
           ROUND(AVG((after_sales - before_sales) * 100.0 / before_sales),4)
    FROM demo_vals

    UNION ALL
    SELECT 'customer_type',
           ROUND(AVG((after_sales - before_sales) * 100.0 / before_sales),4)
    FROM custtype_vals
)

/* ---- 3.  Final list with the attribute type causing the biggest drop ---- */
SELECT
    attribute_type,
    avg_pct_change,
    CASE
        WHEN avg_pct_change = (SELECT MIN(avg_pct_change) FROM avg_changes)
        THEN 'Highest Negative Impact'
    END AS impact_flag
FROM avg_changes
ORDER BY avg_pct_change;