/* 1)  Aggregate monthly litres sold per category
   2)  Work only from 2022-01-01 up to, but not including, the current month (i.e. last fully completed month)
   3)  Compute each category’s monthly share of total litres sold
   4)  Keep categories that
          – appear in at least 24 months, and
          – contribute on average ≥ 1 % of monthly volume
   5)  For every pair of those categories, calculate the Pearson correlation
       between their monthly shares
   6)  Return the two categories with the lowest correlation                */
WITH monthly_cat_volume AS (           -- litres by month & category
    SELECT
        DATE_TRUNC('month', "date")          AS month,
        "category_name"                      AS category,
        SUM("volume_sold_liters")            AS volume_ltr
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" < DATE_TRUNC('month', CURRENT_DATE)   -- exclude current (partial) month
      AND "category_name" IS NOT NULL
    GROUP BY month, category
),
monthly_total_volume AS (              -- total litres each month
    SELECT month,
           SUM(volume_ltr) AS tot_ltr
    FROM monthly_cat_volume
    GROUP BY month
),
category_monthly_share AS (            -- share of total litres each month
    SELECT
        m.month,
        m.category,
        m.volume_ltr / t.tot_ltr AS share
    FROM monthly_cat_volume m
    JOIN monthly_total_volume t USING (month)
),
eligible_categories AS (               -- categories meeting 1 % & ≥24-month rules
    SELECT
        category
    FROM category_monthly_share
    GROUP BY category
    HAVING AVG(share) >= 0.01          -- ≥ 1 % average share
       AND COUNT(*) >= 24              -- present in ≥ 24 months
),
category_pairs AS (                    -- every ordered pair cat1 < cat2
    SELECT
        e1.category AS cat1,
        e2.category AS cat2
    FROM eligible_categories e1
    JOIN eligible_categories e2
      ON e1.category < e2.category
),
pair_correlations AS (                 -- Pearson correlation per pair
    SELECT
        p.cat1,
        p.cat2,
        CORR(s1.share, s2.share) AS corr_val
    FROM category_pairs p
    JOIN category_monthly_share s1
      ON s1.category = p.cat1
    JOIN category_monthly_share s2
      ON s2.category = p.cat2
     AND s1.month    = s2.month        -- match same month
    GROUP BY p.cat1, p.cat2
)
SELECT
    cat1  AS category_1,
    cat2  AS category_2
FROM pair_correlations
ORDER BY corr_val ASC NULLS LAST       -- lowest correlation first
LIMIT 1;