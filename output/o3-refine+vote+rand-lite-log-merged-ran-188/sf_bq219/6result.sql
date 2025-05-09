WITH filtered_sales AS (
    /* 1.  Take data from 2022‑01‑01 through the last fully‑completed month  */
    SELECT
        DATE_TRUNC('month', "date")                    AS month_start,
        "category_name",
        COALESCE(SUM("volume_sold_liters"),0)          AS month_vol_liters
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" <  DATE_TRUNC('month', CURRENT_DATE())      -- exclude current (partial) month
    GROUP BY 1,2
),
month_totals AS (
    /* 2.  Total volume each month (all categories combined) */
    SELECT
        month_start,
        SUM(month_vol_liters)  AS total_month_vol
    FROM filtered_sales
    GROUP BY 1
),
month_pct AS (
    /* 3.  Percentage that each category contributes each month */
    SELECT
        fs.month_start,
        fs."category_name",
        fs.month_vol_liters / mt.total_month_vol   AS pct_of_month
    FROM filtered_sales fs
    JOIN month_totals  mt
          ON mt.month_start = fs.month_start
),
eligible_categories AS (
    /* 4.  Keep categories that appear in ≥24 months and average ≥1 % share */
    SELECT
        "category_name",
        COUNT(*)                    AS months_present,
        AVG(pct_of_month)           AS avg_month_pct
    FROM month_pct
    GROUP BY "category_name"
    HAVING months_present >= 24
       AND avg_month_pct  >= 0.01          -- 1 %
),
eligible_month_pct AS (
    /* 5.  Monthly percentages for just the eligible categories */
    SELECT mp.*
    FROM   month_pct mp
    JOIN   eligible_categories ec
           ON ec."category_name" = mp."category_name"
),
pair_correlations AS (
    /* 6.  Correlation of monthly % shares between every unordered pair */
    SELECT
        a."category_name"  AS category1,
        b."category_name"  AS category2,
        CORR(a.pct_of_month , b.pct_of_month)  AS corr_coef
    FROM   eligible_month_pct a
    JOIN   eligible_month_pct b
           ON a.month_start = b.month_start
          AND a."category_name" < b."category_name"       -- avoid duplicates/self
    GROUP BY category1, category2
)
SELECT
    category1   AS lowest_corr_category_1,
    category2   AS lowest_corr_category_2
FROM   pair_correlations
ORDER  BY corr_coef ASC NULLS LAST
LIMIT 1;