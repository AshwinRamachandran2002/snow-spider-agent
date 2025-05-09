WITH monthly AS (
    SELECT
        DATE_TRUNC('month', "date")             AS "month",
        "category_name",
        SUM("volume_sold_liters")               AS "cat_liters"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= '2022-01-01'
      AND "date" < DATE_TRUNC('month', CURRENT_DATE)      -- last fully completed month
    GROUP BY 1, 2
),
month_tot AS (
    SELECT
        "month",
        SUM("cat_liters")                       AS "total_liters"
    FROM monthly
    GROUP BY 1
),
pct AS (
    SELECT
        m."month",
        m."category_name",
        m."cat_liters" / t."total_liters"       AS "pct_of_total"
    FROM monthly m
    JOIN month_tot t USING ("month")
),
qualified AS (                                  -- ≥ 24 months and ≥ 1 % average share
    SELECT
        "category_name"
    FROM pct
    GROUP BY 1
    HAVING COUNT(*) >= 24
       AND AVG("pct_of_total") >= 0.01
),
q_pct AS (
    SELECT p.*
    FROM   pct p
    JOIN   qualified q USING ("category_name")
),
pairs AS (                                      -- Pearson correlation for every qualifying pair
    SELECT
        a."category_name"                            AS "cat1",
        b."category_name"                            AS "cat2",
        CORR(a."pct_of_total", b."pct_of_total")     AS "corr_coeff"
    FROM q_pct a
    JOIN q_pct b
      ON a."month" = b."month"
     AND a."category_name" < b."category_name"
    GROUP BY 1, 2
)
SELECT
    "cat1"                          AS "category_1",
    "cat2"                          AS "category_2",
    ROUND("corr_coeff", 4)          AS "pearson_correlation"
FROM pairs
ORDER BY "corr_coeff"     -- lowest (most negative) correlation first
LIMIT 1;