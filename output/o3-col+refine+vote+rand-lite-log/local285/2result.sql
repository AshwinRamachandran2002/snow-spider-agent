WITH wholesale_stats AS (
    SELECT substr(w."whsle_date",1,4)                                     AS "year",
           c."category_name",
           AVG(w."whsle_px_rmb-kg")                                       AS "avg_wholesale_price",
           MAX(w."whsle_px_rmb-kg")                                       AS "max_wholesale_price",
           MIN(w."whsle_px_rmb-kg")                                       AS "min_wholesale_price",
           MAX(w."whsle_px_rmb-kg") - MIN(w."whsle_px_rmb-kg")            AS "wholesale_price_diff"
    FROM "veg_whsle_df"  w
    JOIN "veg_cat"       c ON w."item_code" = c."item_code"
    GROUP BY "year", c."category_name"
),
wholesale_cost AS (
    SELECT substr(t."txn_date",1,4)                                       AS "year",
           c."category_name",
           SUM(t."qty_sold(kg)" * w."whsle_px_rmb-kg")                    AS "total_wholesale_cost"
    FROM "veg_txn_df"   t
    JOIN "veg_whsle_df" w ON t."item_code" = w."item_code"
                         AND t."txn_date"  = w."whsle_date"
    JOIN "veg_cat"      c ON t."item_code" = c."item_code"
    GROUP BY "year", c."category_name"
),
selling_revenue AS (
    SELECT substr(t."txn_date",1,4)                                       AS "year",
           c."category_name",
           SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg")             AS "total_selling_price"
    FROM "veg_txn_df" t
    JOIN "veg_cat"    c ON t."item_code" = c."item_code"
    GROUP BY "year", c."category_name"
),
loss_rate AS (
    SELECT c."category_name",
           AVG(l."loss_rate_%")                                           AS "avg_loss_rate"
    FROM "veg_loss_rate_df" l
    JOIN "veg_cat"        c ON l."item_code" = c."item_code"
    GROUP BY c."category_name"
)
SELECT ws."year",
       ws."category_name",
       ROUND(ws."avg_wholesale_price",2)                                  AS "avg_wholesale_price",
       ROUND(ws."max_wholesale_price",2)                                  AS "max_wholesale_price",
       ROUND(ws."min_wholesale_price",2)                                  AS "min_wholesale_price",
       ROUND(ws."wholesale_price_diff",2)                                 AS "wholesale_price_diff",
       ROUND(wc."total_wholesale_cost",2)                                 AS "total_wholesale_cost",
       ROUND(sr."total_selling_price",2)                                  AS "total_selling_price",
       ROUND(lr."avg_loss_rate",2)                                        AS "avg_loss_rate_pct",
       ROUND(wc."total_wholesale_cost" * lr."avg_loss_rate" / 100.0, 2)   AS "total_loss",
       ROUND(sr."total_selling_price"
             - wc."total_wholesale_cost"
             - wc."total_wholesale_cost" * lr."avg_loss_rate" / 100.0, 2) AS "profit"
FROM   wholesale_stats ws
JOIN   wholesale_cost  wc ON ws."year" = wc."year"
                         AND ws."category_name" = wc."category_name"
JOIN   selling_revenue  sr ON ws."year" = sr."year"
                         AND ws."category_name" = sr."category_name"
JOIN   loss_rate        lr ON ws."category_name" = lr."category_name"
WHERE  ws."year" BETWEEN '2020' AND '2023'
ORDER BY ws."year",
         ws."category_name";