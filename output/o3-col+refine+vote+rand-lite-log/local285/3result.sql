WITH wholesale_stats AS (            -- 1. yearly wholesale-price statistics
    SELECT substr(v."whsle_date",1,4)                          AS "year",
           c."category_name",
           AVG(v."whsle_px_rmb-kg")                            AS avg_wholesale_px,
           MAX(v."whsle_px_rmb-kg")                            AS max_wholesale_px,
           MIN(v."whsle_px_rmb-kg")                            AS min_wholesale_px,
           MAX(v."whsle_px_rmb-kg") - MIN(v."whsle_px_rmb-kg") AS wholesale_px_diff
    FROM   "veg_whsle_df" v
    JOIN   "veg_cat"      c ON v."item_code" = c."item_code"
    WHERE  substr(v."whsle_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY "year", c."category_name"
),
wholesale_cost AS (               -- 2. total wholesale cost (price × kg sold)
    SELECT substr(t."txn_date",1,4) AS "year",
           c."category_name",
           SUM(t."qty_sold(kg)" * v."whsle_px_rmb-kg") AS total_wholesale_price
    FROM   "veg_txn_df"   t
    JOIN   "veg_cat"      c ON t."item_code" = c."item_code"
    JOIN   "veg_whsle_df" v 
           ON t."item_code" = v."item_code"
          AND substr(t."txn_date",1,4) = substr(v."whsle_date",1,4)
    WHERE  substr(t."txn_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY "year", c."category_name"
),
selling_revenue AS (              -- 3. total selling revenue
    SELECT substr(t."txn_date",1,4) AS "year",
           c."category_name",
           SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg") AS total_selling_price
    FROM   "veg_txn_df" t
    JOIN   "veg_cat"    c ON t."item_code" = c."item_code"
    WHERE  substr(t."txn_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY "year", c."category_name"
),
loss_rate AS (                    -- 4. average physical loss rate (time-invariant)
    SELECT c."category_name",
           AVG(l."loss_rate_%") AS avg_loss_rate
    FROM   "veg_loss_rate_df" l
    JOIN   "veg_cat"          c ON l."item_code" = c."item_code"
    GROUP  BY c."category_name"
)

SELECT ws."year",
       ws."category_name",
       ROUND(ws.avg_wholesale_px,2)          AS "avg_wholesale_px",
       ROUND(ws.max_wholesale_px,2)          AS "max_wholesale_px",
       ROUND(ws.min_wholesale_px,2)          AS "min_wholesale_px",
       ROUND(ws.wholesale_px_diff,2)         AS "wholesale_px_diff",
       ROUND(wc.total_wholesale_price,2)     AS "total_wholesale_price",
       ROUND(sr.total_selling_price,2)       AS "total_selling_price",
       ROUND(lr.avg_loss_rate,2)             AS "avg_loss_rate_%",
       ROUND(wc.total_wholesale_price 
             * lr.avg_loss_rate / 100.0,2)   AS "total_loss",
       ROUND(sr.total_selling_price
             - wc.total_wholesale_price
             - wc.total_wholesale_price * lr.avg_loss_rate / 100.0,2) 
                                             AS "profit"
FROM   wholesale_stats ws
LEFT   JOIN wholesale_cost   wc ON ws."year" = wc."year" 
                               AND ws."category_name" = wc."category_name"
LEFT   JOIN selling_revenue  sr ON ws."year" = sr."year" 
                               AND ws."category_name" = sr."category_name"
LEFT   JOIN loss_rate        lr ON ws."category_name" = lr."category_name"
ORDER  BY ws."year", ws."category_name";