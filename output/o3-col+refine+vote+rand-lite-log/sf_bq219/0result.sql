/*  Two categories (2022-present) whose monthly %-shares are the
    least correlated, subject to:
        • average share ≥ 1 %
        • observed in ≥ 24 months of the period
*/
WITH
-- 1) Monthly litres by category (2022-01-01 .. last full month)
cat_month AS (
    SELECT DATE_TRUNC('month', "date")              AS "month",
           "category_name",
           SUM("volume_sold_liters")                AS "cat_liters"
    FROM   "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE  "date" >= '2022-01-01'
       AND "date" <  DATE_TRUNC('month', CURRENT_DATE)   -- exclude current partial month
    GROUP  BY "month", "category_name"
),

-- 2) Total litres each month
tot_month AS (
    SELECT DATE_TRUNC('month', "date")              AS "month",
           SUM("volume_sold_liters")                AS "total_liters"
    FROM   "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE  "date" >= '2022-01-01'
       AND "date" <  DATE_TRUNC('month', CURRENT_DATE)
    GROUP  BY "month"
),

-- 3) Monthly % share per category
pct AS (
    SELECT c."month",
           c."category_name",
           100 * c."cat_liters" / t."total_liters"  AS "pct_total"
    FROM   cat_month c
    JOIN   tot_month t USING ("month")
),

-- 4) Keep categories that average ≥1 % share over ≥24 months
eligible_cats AS (
    SELECT "category_name"
    FROM   pct
    GROUP  BY "category_name"
    HAVING AVG("pct_total") >= 1
       AND COUNT(*)         >= 24
),

-- 5) Percent-share rows limited to eligible categories
pct_eligible AS (
    SELECT p.*
    FROM   pct p
    JOIN   eligible_cats e USING ("category_name")
),

-- 6) Pairwise Pearson correlations
pair_corr AS (
    SELECT p1."category_name"                       AS "category_1",
           p2."category_name"                       AS "category_2",
           CORR(p1."pct_total", p2."pct_total")     AS "corr_coeff"
    FROM   pct_eligible p1
    JOIN   pct_eligible p2
           ON p1."month" = p2."month"
          AND p1."category_name" < p2."category_name"   -- avoid duplicates & self-joins
    GROUP  BY "category_1", "category_2"
)

-- 7) The two categories with the lowest correlation
SELECT "category_1",
       "category_2",
       "corr_coeff"
FROM   pair_corr
ORDER  BY "corr_coeff" ASC NULLS LAST
LIMIT 1;