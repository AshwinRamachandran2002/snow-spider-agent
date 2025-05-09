WITH filtered_sales AS (
    SELECT
        DATE_TRUNC('MONTH', "date")                                     AS month,
        "category_name",
        "volume_sold_liters"
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" < DATE_TRUNC('MONTH', CURRENT_DATE())      -- last full month
      AND "volume_sold_liters" IS NOT NULL
      AND "category_name" IS NOT NULL
), monthly_totals AS (
    SELECT
        month,
        SUM("volume_sold_liters")                                      AS total_liters
    FROM filtered_sales
    GROUP BY month
), monthly_category AS (
    SELECT
        fs.month,
        fs."category_name",
        SUM(fs."volume_sold_liters")                                   AS cat_liters
    FROM filtered_sales fs
    GROUP BY fs.month, fs."category_name"
), monthly_pct AS (
    SELECT
        mc.month,
        mc."category_name",
        mc.cat_liters / mt.total_liters                                AS pct_of_month
    FROM monthly_category mc
    JOIN monthly_totals mt
      ON mc.month = mt.month
), category_stats AS (
    SELECT
        "category_name",
        AVG(pct_of_month)                                              AS avg_monthly_pct,
        COUNT(month)                                                   AS months_available
    FROM monthly_pct
    GROUP BY "category_name"
    HAVING AVG(pct_of_month) >= 0.01          -- at least 1% on average
       AND COUNT(month)      >= 24            -- at least 24 months of data
), eligible_pct AS (
    SELECT
        mp.month,
        mp."category_name",
        mp.pct_of_month
    FROM monthly_pct mp
    JOIN category_stats cs
      ON mp."category_name" = cs."category_name"
), pair_correlations AS (
    SELECT
        ep1."category_name"                                           AS category_a,
        ep2."category_name"                                           AS category_b,
        CORR(ep1.pct_of_month, ep2.pct_of_month)                      AS corr_coeff,
        COUNT(*)                                                      AS overlap_months
    FROM eligible_pct ep1
    JOIN eligible_pct ep2
      ON ep1.month = ep2.month
     AND ep1."category_name" < ep2."category_name"   -- avoid duplicates & self‑pairs
    GROUP BY ep1."category_name", ep2."category_name"
    HAVING COUNT(*) >= 24                             -- keep pairs with full overlap
)
SELECT
    category_a,
    category_b
FROM pair_correlations
ORDER BY corr_coeff ASC NULLS LAST                 -- lowest Pearson correlation
LIMIT 1;