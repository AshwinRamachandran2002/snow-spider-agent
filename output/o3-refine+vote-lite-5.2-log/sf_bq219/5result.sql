WITH params AS (
    /* last fully completed month starts at the first day of the previous month */
    SELECT DATE_TRUNC('MONTH', CURRENT_DATE())          AS current_month_start,
           DATE '2022-01-01'                            AS analysis_start
),
monthly_vol AS (
    /* total litres by month & category from 1‑Jan‑2022 through last full month */
    SELECT
        DATE_TRUNC('MONTH', "date")           AS month,
        "category_name",
        SUM("volume_sold_liters")             AS litres
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES, params
    WHERE "date" >= params.analysis_start
      AND "date" <  params.current_month_start
    GROUP BY month, "category_name"
),
monthly_pct AS (
    /* % share of each category in that month */
    SELECT
        month,
        "category_name",
        litres / SUM(litres) OVER (PARTITION BY month)  AS pct
    FROM monthly_vol
),
qualifying_categories AS (
    /* categories that (1) appear in ≥24 months  (2) average ≥1 % share */
    SELECT
        "category_name"
    FROM monthly_pct
    GROUP BY "category_name"
    HAVING COUNT(*) >= 24
       AND AVG(pct) >= 0.01            -- 1 % expressed as a proportion
),
monthly_pct_q AS (
    /* keep only qualifying categories */
    SELECT *
    FROM monthly_pct
    WHERE "category_name" IN (SELECT "category_name" FROM qualifying_categories)
),
pair_correlations AS (
    /* Pearson correlation of monthly % shares for every category pair */
    SELECT
        p1."category_name"  AS cat1,
        p2."category_name"  AS cat2,
        CORR(p1.pct, p2.pct) AS corr_val
    FROM monthly_pct_q p1
    JOIN monthly_pct_q p2
          ON p1.month = p2.month
         AND p1."category_name" < p2."category_name"   -- avoid duplicates & self‑join
    GROUP BY cat1, cat2
)
SELECT cat1 AS category_1,
       cat2 AS category_2
FROM pair_correlations
ORDER BY corr_val ASC NULLS LAST
LIMIT 1;