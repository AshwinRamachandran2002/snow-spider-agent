WITH
-- 1.  Define the analysis window:  from 1-Jan-2022 through the last fully-completed month
dates AS (
    SELECT
        DATE_TRUNC('MONTH', "date")                       AS month
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" <  DATE_TRUNC('MONTH', CURRENT_DATE)     -- exclude the current (partial) month
    GROUP BY 1
),

-- 2.  Monthly litres sold per category inside that window
monthly_category_volume AS (
    SELECT
        DATE_TRUNC('MONTH', "date")           AS month,
        "category_name"                       AS category,
        SUM("volume_sold_liters")             AS volume_liters
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" <  DATE_TRUNC('MONTH', CURRENT_DATE)
    GROUP BY 1, 2
),

-- 3.  Total litres sold each month (all categories)
monthly_totals AS (
    SELECT
        month,
        SUM(volume_liters) AS total_litres
    FROM monthly_category_volume
    GROUP BY month
),

-- 4.  Percentage share of each category for the months where it appears
monthly_pct_raw AS (
    SELECT
        mcv.month,
        mcv.category,
        mcv.volume_liters / mt.total_litres AS pct
    FROM monthly_category_volume mcv
    JOIN monthly_totals      mt  USING (month)
),

-- 5.  Ensure every category has a row for every month (missing = 0 %)
all_months_categories AS (
    SELECT
        d.month,
        c.category
    FROM dates d
    CROSS JOIN ( SELECT DISTINCT category FROM monthly_category_volume ) c
),

monthly_pct AS (
    SELECT
        amc.month,
        amc.category,
        COALESCE(mpr.pct, 0) AS pct
    FROM all_months_categories amc
    LEFT JOIN monthly_pct_raw mpr
           ON mpr.month    = amc.month
          AND mpr.category = amc.category
),

-- 6.  Keep only categories that
--     a) have data for at least 24 months
--     b) average ≥ 1 % of total monthly volume over the whole period
eligible_categories AS (
    SELECT
        category
    FROM monthly_pct
    GROUP BY category
    HAVING COUNT(*)                          >= 24      -- at least 24 months
       AND AVG(pct)                          >= 0.01    -- ≥ 1 % average share
),

-- 7.  Percent-share time-series for eligible categories only
eligible_pct AS (
    SELECT mp.*
    FROM   monthly_pct mp
    JOIN   eligible_categories ec USING (category)
),

-- 8.  Pair every distinct pair of eligible categories,
--     align by month, and compute the Pearson correlation of their % shares
pair_correlations AS (
    SELECT
        e1.category                  AS category1,
        e2.category                  AS category2,
        CORR(e1.pct, e2.pct)         AS corr_coef
    FROM   eligible_pct e1
    JOIN   eligible_pct e2
           ON  e1.month     = e2.month
           AND e1.category  < e2.category          -- ensures each unordered pair is computed once
    GROUP BY
        category1, category2
    HAVING corr_coef IS NOT NULL
)

-- 9.  Return the pair with the LOWEST correlation coefficient
SELECT
    category1,
    category2
FROM   pair_correlations
ORDER BY
    corr_coef ASC NULLS LAST
LIMIT 1;