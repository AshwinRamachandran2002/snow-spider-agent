WITH maxm AS (                     -- first day of the most-recent month that has data
    SELECT DATE_TRUNC('month', MAX("date")) AS max_month_start
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
),
filtered AS (                      -- keep data 2022-01-01 up to, but not including, that month
    SELECT s.*
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES" s
    CROSS JOIN maxm m
    WHERE s."date" >= '2022-01-01'
      AND s."date" <  m.max_month_start
),
month_tot AS (                     -- total litres sold each month
    SELECT DATE_TRUNC('month', "date") AS "month",
           SUM("volume_sold_liters")   AS tot_litres
    FROM filtered
    GROUP BY "month"
),
cat_month AS (                     -- litres per category per month
    SELECT DATE_TRUNC('month', "date") AS "month",
           "category_name",
           SUM("volume_sold_liters")   AS cat_litres
    FROM filtered
    GROUP BY "month", "category_name"
),
pct AS (                           -- category’s % share of that month’s litres
    SELECT c."month",
           c."category_name",
           100.0 * c.cat_litres / m.tot_litres AS pct_of_month
    FROM cat_month c
    JOIN month_tot m
      ON c."month" = m."month"
),
qual AS (                          -- categories in ≥24 months & ≥1 % avg share
    SELECT "category_name"
    FROM pct
    GROUP BY "category_name"
    HAVING COUNT(DISTINCT "month") >= 24
       AND AVG(pct_of_month)       >= 1
),
matrix AS (                        -- align qualified pairs for correlation
    SELECT p1."month",
           p1."category_name" AS cat1,
           p2."category_name" AS cat2,
           p1.pct_of_month    AS pct1,
           p2.pct_of_month    AS pct2
    FROM pct p1
    JOIN pct p2
      ON p1."month" = p2."month"
     AND p1."category_name" < p2."category_name"
    WHERE p1."category_name" IN (SELECT "category_name" FROM qual)
      AND p2."category_name" IN (SELECT "category_name" FROM qual)
),
pair_corr AS (                     -- Pearson correlation for every pair
    SELECT cat1,
           cat2,
           CORR(pct1, pct2) AS pearson_corr
    FROM matrix
    GROUP BY cat1, cat2
),
answer AS (                        -- lowest (most-negative) correlation
    SELECT *
    FROM pair_corr
    WHERE pearson_corr IS NOT NULL
    ORDER BY pearson_corr ASC NULLS LAST
    LIMIT 1
)
SELECT cat1          AS "category_1",
       cat2          AS "category_2",
       pearson_corr  AS "pearson_correlation"
FROM answer;