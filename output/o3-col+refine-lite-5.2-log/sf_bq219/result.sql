/* ---------------------------------------------------------------
   Lowest‑correlated qualifying liquor categories
---------------------------------------------------------------*/
WITH last_full_month_start AS (      -- first day of the most‑recent partial month
    SELECT DATE_TRUNC('month', MAX("date")) AS first_day_partial_month
    FROM   IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
),

filtered_sales AS (                  -- 2022‑01‑01 … last complete month
    SELECT *
    FROM   IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES, last_full_month_start
    WHERE  "date" >= '2022-01-01'
       AND "date" < first_day_partial_month
),

monthly_pct AS (                     -- litres & % share per month / category
    SELECT
        DATE_TRUNC('month', "date")                       AS "sales_month",
        "category_name",
        SUM("volume_sold_liters")                         AS "liters_sold",
        SUM("volume_sold_liters")
          / SUM(SUM("volume_sold_liters")) OVER (PARTITION BY DATE_TRUNC('month', "date"))
                                                        AS "pct_of_month"
    FROM   filtered_sales
    GROUP  BY 1, 2
),

qualifying_cats AS (                 -- ≥24 months & ≥1 % avg share
    SELECT  "category_name"
    FROM    monthly_pct
    GROUP   BY 1
    HAVING  COUNT(*)            >= 24
       AND  AVG("pct_of_month") >= 0.01
),

base AS (                            -- only qualifying categories
    SELECT *
    FROM   monthly_pct
    WHERE  "category_name" IN (SELECT "category_name" FROM qualifying_cats)
),

corr_pairs AS (                      -- pair‑wise Pearson correlations
    SELECT
        a."category_name"                               AS "category_one",
        b."category_name"                               AS "category_two",
        CORR(a."pct_of_month", b."pct_of_month")        AS "pearson_corr"
    FROM   base a
    JOIN   base b
           ON a."sales_month"   = b."sales_month"
          AND a."category_name" < b."category_name"
    GROUP  BY a."category_name", b."category_name"
)

SELECT  "category_one",
        "category_two",
        "pearson_corr"
FROM    corr_pairs
ORDER BY "pearson_corr" ASC
LIMIT 1;