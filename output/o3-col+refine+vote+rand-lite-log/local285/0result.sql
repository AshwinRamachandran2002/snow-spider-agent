/*  Financial performance 2020-2023 by vegetable category  */
WITH whsle AS (               -- 1. wholesale statistics
    SELECT
        substr(vw."whsle_date",1,4)          AS "year",
        vc."category_name",
        ROUND(AVG(vw."whsle_px_rmb-kg"),2)   AS "avg_wholesale_px",
        ROUND(MAX(vw."whsle_px_rmb-kg"),2)   AS "max_wholesale_px",
        ROUND(MIN(vw."whsle_px_rmb-kg"),2)   AS "min_wholesale_px",
        ROUND(MAX(vw."whsle_px_rmb-kg") -
              MIN(vw."whsle_px_rmb-kg"),2)   AS "wholesale_px_diff",
        ROUND(SUM(vw."whsle_px_rmb-kg"),2)   AS "total_wholesale_px"
    FROM "veg_whsle_df" vw
    JOIN "veg_cat" AS vc
      ON vw."item_code" = vc."item_code"
    WHERE substr(vw."whsle_date",1,4) BETWEEN '2020' AND '2023'
    GROUP BY "year", vc."category_name"
),
sales AS (                 -- 2. selling revenue
    SELECT
        substr(vt."txn_date",1,4)                         AS "year",
        vc."category_name",
        ROUND(SUM(vt."unit_selling_px_rmb/kg" *
                  vt."qty_sold(kg)"),2)                   AS "total_selling_px"
    FROM "veg_txn_df" vt
    JOIN "veg_cat" AS vc
      ON vt."item_code" = vc."item_code"
    WHERE substr(vt."txn_date",1,4) BETWEEN '2020' AND '2023'
    GROUP BY "year", vc."category_name"
),
loss AS (                  -- 3. average spoilage/loss rate (static per category)
    SELECT
        vc."category_name",
        ROUND(AVG(vl."loss_rate_%"),2) AS "avg_loss_rate_%"
    FROM "veg_loss_rate_df" vl
    JOIN "veg_cat" AS vc
      ON vl."item_code" = vc."item_code"
    GROUP BY vc."category_name"
)
SELECT
    w."year",
    w."category_name",
    w."avg_wholesale_px",
    w."max_wholesale_px",
    w."min_wholesale_px",
    w."wholesale_px_diff",
    w."total_wholesale_px",
    s."total_selling_px",
    l."avg_loss_rate_%",
    ROUND(w."total_wholesale_px" * l."avg_loss_rate_%"/100,2) AS "total_loss_px",
    ROUND(s."total_selling_px" -
          w."total_wholesale_px" -
          (w."total_wholesale_px" * l."avg_loss_rate_%"/100),2) AS "profit_px"
FROM   whsle w
JOIN   sales s ON w."year" = s."year"
              AND w."category_name" = s."category_name"
JOIN   loss  l ON w."category_name" = l."category_name"
ORDER BY w."year", w."category_name";