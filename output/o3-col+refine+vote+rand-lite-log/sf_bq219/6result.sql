WITH date_bounds AS (      -- determine last fully-completed month in the data
    SELECT
        MAX("date")                                                   AS max_date,
        CASE
            WHEN MAX("date") = LAST_DAY(MAX("date"))
                 THEN DATE_TRUNC('month', MAX("date"))                -- month is complete
            ELSE DATEADD(month, -1, DATE_TRUNC('month', MAX("date"))) -- use previous month
        END                                                           AS last_full_month
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
),

monthly_cat AS (           -- litres per category per month (Jan-2022 .. last_full_month)
    SELECT
        DATE_TRUNC('month', s."date")                  AS month,
        s."category_name",
        SUM(s."volume_sold_liters")                    AS cat_liters
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"  s
    JOIN date_bounds db ON 1 = 1
    WHERE s."date" >= '2022-01-01'
      AND s."date" <  DATEADD(month, 1, db.last_full_month)           -- exclude partial month (if any)
    GROUP BY 1, 2
),

monthly_share AS (         -- add each category’s share of its month’s total litres
    SELECT
        mc.month,
        mc."category_name",
        mc.cat_liters,
        mc.cat_liters
          / SUM(mc.cat_liters) OVER (PARTITION BY mc.month)  AS pct_of_month
    FROM monthly_cat mc
),

qualifying AS (            -- keep categories averaging ≥1 % share & appearing in ≥24 months
    SELECT
        "category_name"
    FROM monthly_share
    GROUP BY "category_name"
    HAVING AVG(pct_of_month) >= 0.01
       AND COUNT(*)          >= 24
),

pairs AS (                 -- every unordered pair of qualifying categories
    SELECT
        q1."category_name" AS cat1,
        q2."category_name" AS cat2
    FROM qualifying q1
    JOIN qualifying q2
      ON q1."category_name" < q2."category_name"
),

correlations AS (          -- Pearson correlation of the two categories’ monthly shares
    SELECT
        p.cat1,
        p.cat2,
        CORR(s1.pct_of_month, s2.pct_of_month) AS pearson_corr
    FROM pairs p
    JOIN monthly_share s1 ON s1."category_name" = p.cat1
    JOIN monthly_share s2 ON s2."category_name" = p.cat2
                         AND s1.month           = s2.month
    GROUP BY p.cat1, p.cat2
)

SELECT
    cat1 AS category_name_1,
    cat2 AS category_name_2,
    pearson_corr
FROM correlations
ORDER BY pearson_corr ASC
LIMIT 1;