WITH dates AS (
    SELECT
        date('2020-06-15')                      AS mid_dt,
        date('2020-06-15','-12 weeks')          AS pre_start,
        date('2020-06-15')                      AS post_start,
        date('2020-06-15','+12 weeks')          AS post_end
),

/* ---------------------------------------------------------------
   Aggregate sales for every value of each attribute type,
   capturing its totals in the 12‑week PRE and POST periods.
---------------------------------------------------------------- */
sales_by_attr AS (
    /* -------- region -------- */
    SELECT 'region' AS attribute_type,
           region   AS attribute_value,
           SUM(CASE WHEN week_date >= pre_start  AND week_date < mid_dt  THEN sales END) AS pre_sales,
           SUM(CASE WHEN week_date >= post_start AND week_date < post_end THEN sales END) AS post_sales
    FROM cleaned_weekly_sales, dates
    GROUP BY region

    UNION ALL
    /* -------- platform -------- */
    SELECT 'platform',
           platform,
           SUM(CASE WHEN week_date >= pre_start  AND week_date < mid_dt  THEN sales END),
           SUM(CASE WHEN week_date >= post_start AND week_date < post_end THEN sales END)
    FROM cleaned_weekly_sales, dates
    GROUP BY platform

    UNION ALL
    /* -------- age_band -------- */
    SELECT 'age_band',
           age_band,
           SUM(CASE WHEN week_date >= pre_start  AND week_date < mid_dt  THEN sales END),
           SUM(CASE WHEN week_date >= post_start AND week_date < post_end THEN sales END)
    FROM cleaned_weekly_sales, dates
    GROUP BY age_band

    UNION ALL
    /* -------- demographic -------- */
    SELECT 'demographic',
           demographic,
           SUM(CASE WHEN week_date >= pre_start  AND week_date < mid_dt  THEN sales END),
           SUM(CASE WHEN week_date >= post_start AND week_date < post_end THEN sales END)
    FROM cleaned_weekly_sales, dates
    GROUP BY demographic

    UNION ALL
    /* -------- customer_type -------- */
    SELECT 'customer_type',
           customer_type,
           SUM(CASE WHEN week_date >= pre_start  AND week_date < mid_dt  THEN sales END),
           SUM(CASE WHEN week_date >= post_start AND week_date < post_end THEN sales END)
    FROM cleaned_weekly_sales, dates
    GROUP BY customer_type
),

/* ---------------------------------------------------------------
   % change for each individual attribute value
---------------------------------------------------------------- */
pct_change AS (
    SELECT
        attribute_type,
        attribute_value,
        pre_sales,
        post_sales,
        CASE
            WHEN pre_sales IS NULL OR pre_sales = 0 THEN NULL
            ELSE (post_sales - pre_sales) * 100.0 / pre_sales
        END AS pct_change
    FROM sales_by_attr
),

/* ---------------------------------------------------------------
   Average % change across all values of each attribute type
---------------------------------------------------------------- */
avg_change AS (
    SELECT
        attribute_type,
        COALESCE(AVG(pct_change),0) AS avg_pct_change
    FROM pct_change
    GROUP BY attribute_type
),

/* ---------------------------------------------------------------
   Attribute type with the largest negative (smallest) average % change
---------------------------------------------------------------- */
worst AS (
    SELECT attribute_type
    FROM   avg_change
    ORDER  BY avg_pct_change ASC
    LIMIT  1
)

/* ---------------------------------------------------------------
   Final output
---------------------------------------------------------------- */
SELECT
    a.attribute_type,
    ROUND(a.avg_pct_change,4) AS avg_pct_change,
    CASE WHEN a.attribute_type = w.attribute_type THEN 1 ELSE 0 END AS highest_negative_impact_flag
FROM   avg_change AS a
CROSS  JOIN worst      AS w
ORDER  BY highest_negative_impact_flag DESC, a.attribute_type;