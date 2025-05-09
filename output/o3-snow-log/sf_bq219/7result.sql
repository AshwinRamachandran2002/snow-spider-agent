WITH
/* 1. last fully-completed month present in the data */
max_date_cte AS (
    SELECT MAX("date") AS max_date
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
),
last_full_month_cte AS (
    SELECT CASE
             WHEN max_date < LAST_DAY(max_date)
                  THEN DATEADD(month, -1, DATE_TRUNC('month', max_date))
             ELSE DATE_TRUNC('month', max_date)
           END AS last_full_month
    FROM max_date_cte
),

/* 2. litres sold per category per month inside the required window */
monthly_category AS (
    SELECT
        DATE_TRUNC('month', "date")          AS month,
        "category_name",
        SUM("volume_sold_liters")            AS litres
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES , last_full_month_cte
    WHERE "date" >= '2022-01-01'
      AND "date" <  DATEADD(month, 1, last_full_month)      -- through last full month (inclusive)
    GROUP BY month, "category_name"
),

/* 3. total litres each month */
monthly_total AS (
    SELECT month,
           SUM(litres)                       AS total_litres
    FROM monthly_category
    GROUP BY month
),

/* 4. category’s share (%) of monthly total */
monthly_pct AS (
    SELECT
        mc.month,
        mc."category_name",
        mc.litres / mt.total_litres          AS pct
    FROM monthly_category mc
    JOIN monthly_total   mt USING (month)
),

/* 5. categories that average ≥ 1 % share across ≥ 24 months */
category_stats AS (
    SELECT
        "category_name",
        COUNT(*)                             AS months_with_sales,
        AVG(pct)                             AS avg_pct
    FROM monthly_pct
    GROUP BY "category_name"
),
qualified_categories AS (
    SELECT "category_name"
    FROM category_stats
    WHERE months_with_sales >= 24
      AND avg_pct           >= 0.01          -- 1 %
),

/* 6. monthly % values for only the qualified categories */
qualified_pct AS (
    SELECT mp.month,
           mp."category_name",
           mp.pct
    FROM   monthly_pct mp
    JOIN   qualified_categories qc
           ON mp."category_name" = qc."category_name"
),

/* 7. pair-wise Pearson correlations of the monthly % series */
pair_corr AS (
    SELECT
        q1."category_name"                   AS cat1,
        q2."category_name"                   AS cat2,
        CORR(q1.pct, q2.pct)                 AS corr_value
    FROM qualified_pct q1
    JOIN qualified_pct q2
          ON q1.month = q2.month
         AND q1."category_name" < q2."category_name"
    GROUP BY cat1, cat2
)

/* 8. lowest correlation pair */
SELECT
    cat1 AS category_name_1,
    cat2 AS category_name_2
FROM pair_corr
ORDER BY corr_value ASC NULLS LAST
LIMIT 1;