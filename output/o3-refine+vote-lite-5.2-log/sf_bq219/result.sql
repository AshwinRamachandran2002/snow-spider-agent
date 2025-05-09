WITH params AS (   -- determine the last fully‑completed month in the data
    SELECT
        CASE
            WHEN MAX("date") >= LAST_DAY(MAX("date"))
            THEN DATE_TRUNC('month', MAX("date"))                 -- month is complete
            ELSE DATEADD(month, -1, DATE_TRUNC('month', MAX("date")))  -- step back one month
        END AS last_full_month_start
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
),

filtered_sales AS (  -- restrict to 2022‑01‑01 through the last full month
    SELECT
        DATE_TRUNC('month', "date") AS month,
        "category_name",
        "volume_sold_liters"
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES, params
    WHERE "date" >= '2022-01-01'
      AND "date" < DATEADD(month, 1, last_full_month_start)       -- end of last full month
),

month_category_vol AS (          -- litres per category per month
    SELECT
        month,
        "category_name",
        SUM("volume_sold_liters") AS vol_liters
    FROM filtered_sales
    GROUP BY month, "category_name"
),

month_totals AS (                -- total litres per month
    SELECT
        month,
        SUM(vol_liters) AS total_vol
    FROM month_category_vol
    GROUP BY month
),

category_month_pct AS (          -- category’s share of monthly volume
    SELECT
        mcv.month,
        mcv."category_name",
        mcv.vol_liters / mt.total_vol AS pct
    FROM month_category_vol  mcv
    JOIN month_totals        mt
          ON mcv.month = mt.month
),

eligible_categories AS (         -- categories meeting 1 % avg share & >=24 months
    SELECT
        "category_name",
        COUNT(*)          AS months_present,
        AVG(pct)          AS avg_monthly_pct
    FROM category_month_pct
    GROUP BY "category_name"
    HAVING COUNT(*) >= 24
       AND AVG(pct)  >= 0.01      -- ≥1 %
),

pair_correlations AS (           -- Pearson correlations for every eligible pair
    SELECT
        c1."category_name" AS cat1,
        c2."category_name" AS cat2,
        CORR(p1.pct, p2.pct) AS corr_coeff
    FROM eligible_categories c1
    JOIN eligible_categories c2
          ON c1."category_name" < c2."category_name"
    JOIN category_month_pct p1
          ON p1."category_name" = c1."category_name"
    JOIN category_month_pct p2
          ON p2."category_name" = c2."category_name"
         AND p1.month            = p2.month
    GROUP BY cat1, cat2
)

SELECT
    cat1 AS "CATEGORY_1",
    cat2 AS "CATEGORY_2"
FROM pair_correlations
ORDER BY corr_coeff ASC NULLS LAST, cat1, cat2     -- lowest correlation first
LIMIT 1;