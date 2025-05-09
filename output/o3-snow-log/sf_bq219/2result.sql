/*  Two liquor categories (category_name) whose monthly share of total volume
    from Jan-2022 through the last fully completed month
    – appears in at least 24 of those months
    – contributes on average ≥ 1 % of the monthly volume
    – have the lowest Pearson correlation between their monthly percentage
*/
WITH
-- 1.  Monthly volume per category (litres) inside the period
monthly_cat_vol AS (
    SELECT
        DATE_TRUNC('month', "date")                  AS month,
        "category_name",
        SUM("volume_sold_liters")                    AS cat_vol_l
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" <  DATE_TRUNC('month', CURRENT_DATE)      -- up to last completed month
    GROUP BY 1, 2
),
-- 2.  Total monthly volume
monthly_total AS (
    SELECT
        month,
        SUM(cat_vol_l)  AS tot_vol_l
    FROM monthly_cat_vol
    GROUP BY month
),
-- 3.  Monthly percentage share per category
monthly_cat_pct AS (
    SELECT
        mcv.month,
        mcv."category_name",
        mcv.cat_vol_l / mt.tot_vol_l AS pct_of_month
    FROM monthly_cat_vol mcv
    JOIN monthly_total mt USING (month)
),
-- 4.  Keep categories that (a) are present in ≥24 months and (b) average ≥1 % share
eligible_cats AS (
    SELECT
        "category_name"
    FROM monthly_cat_pct
    GROUP BY "category_name"
    HAVING COUNT(*) >= 24
       AND AVG(pct_of_month) >= 0.01          -- 1 % expressed as fraction
),
-- 5.  Monthly percentages only for eligible categories
eligible_monthly_pct AS (
    SELECT
        month,
        "category_name",
        pct_of_month
    FROM monthly_cat_pct
    WHERE "category_name" IN (SELECT "category_name" FROM eligible_cats)
),
-- 6.  Pairwise correlation between every distinct pair of categories
pairwise_corr AS (
    SELECT
        a."category_name" AS cat1,
        b."category_name" AS cat2,
        CORR(a.pct_of_month, b.pct_of_month)  AS corr_coef
    FROM eligible_monthly_pct a
    JOIN eligible_monthly_pct b
          ON a.month = b.month
         AND a."category_name" < b."category_name"   -- each unordered pair once
    GROUP BY cat1, cat2
)
-- 7.  Pick the pair with the lowest correlation coefficient
SELECT
    cat1  AS category_name_1,
    cat2  AS category_name_2
FROM pairwise_corr
ORDER BY corr_coef ASC NULLS LAST
FETCH 1;