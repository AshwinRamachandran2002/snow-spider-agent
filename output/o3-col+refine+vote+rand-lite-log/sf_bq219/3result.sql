WITH mon_tot AS (          -- total liters each month
    SELECT
        DATE_TRUNC('month', "date")                   AS mon,
        SUM("volume_sold_liters")                     AS tot_liters
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= '2022-01-01'
      AND "date" <  DATE_TRUNC('month', CURRENT_DATE())
    GROUP BY DATE_TRUNC('month', "date")
),
pct AS (                   -- % share per category per month
    SELECT
        DATE_TRUNC('month', s."date")                 AS mon,
        s."category_name",
        SUM(s."volume_sold_liters") / t.tot_liters * 100  AS pct_month
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES" s
    JOIN mon_tot t
      ON DATE_TRUNC('month', s."date") = t.mon
    WHERE s."date" >= '2022-01-01'
      AND s."date" <  DATE_TRUNC('month', CURRENT_DATE())
    GROUP BY DATE_TRUNC('month', s."date"), s."category_name", t.tot_liters
),
qual AS (                 -- categories meeting ≥24 months & ≥1 % avg share
    SELECT
        "category_name"
    FROM pct
    GROUP BY "category_name"
    HAVING COUNT(*) >= 24
       AND AVG(pct_month) >= 1
),
tbl AS (                  -- keep only qualifying categories
    SELECT
        p.mon,
        p."category_name",
        p.pct_month
    FROM pct p
    JOIN qual q
      ON p."category_name" = q."category_name"
),
pairs AS (                -- correlation of every qualifying category pair
    SELECT
        a."category_name"                                      AS cat1,
        b."category_name"                                      AS cat2,
        CORR(a.pct_month, b.pct_month)                         AS corr_coef
    FROM tbl a
    JOIN tbl b
      ON a.mon = b.mon
     AND a."category_name" < b."category_name"   -- remove duplicates/self-pairs
    GROUP BY a."category_name", b."category_name"
)
SELECT
    cat1        AS "category_1",
    cat2        AS "category_2",
    corr_coef
FROM pairs
ORDER BY corr_coef ASC
LIMIT 1;