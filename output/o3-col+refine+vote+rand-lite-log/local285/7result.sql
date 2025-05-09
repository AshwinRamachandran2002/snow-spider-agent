WITH whsle_stats AS (
    SELECT substr(w."whsle_date",1,4)                                    AS "year",
           c."category_name",
           ROUND(AVG(w."whsle_px_rmb-kg"), 2)                            AS "avg_whsle_px",
           ROUND(MAX(w."whsle_px_rmb-kg"), 2)                            AS "max_whsle_px",
           ROUND(MIN(w."whsle_px_rmb-kg"), 2)                            AS "min_whsle_px",
           ROUND(MAX(w."whsle_px_rmb-kg") - MIN(w."whsle_px_rmb-kg"), 2) AS "whsle_px_diff",
           ROUND(SUM(w."whsle_px_rmb-kg"), 2)                            AS "total_whsle_px"
    FROM   "veg_whsle_df" AS w
    JOIN   "veg_cat"      AS c ON w."item_code" = c."item_code"
    WHERE  substr(w."whsle_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY "year", c."category_name"
),
sales_tot AS (
    SELECT substr(t."txn_date",1,4)                                      AS "year",
           c."category_name",
           ROUND(SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg"), 2)  AS "total_selling_px"
    FROM   "veg_txn_df" AS t
    JOIN   "veg_cat"    AS c ON t."item_code" = c."item_code"
    WHERE  substr(t."txn_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY "year", c."category_name"
),
loss_tot AS (
    SELECT substr(t."txn_date",1,4) AS "year",
           c."category_name",
           ROUND(AVG(l."loss_rate_%"), 2)                                   AS "avg_loss_rate_%",
           ROUND(SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg"
                     * l."loss_rate_%" / 100), 2)                           AS "total_loss"
    FROM   "veg_txn_df"       AS t
    JOIN   "veg_cat"          AS c ON t."item_code" = c."item_code"
    JOIN   "veg_loss_rate_df" AS l ON t."item_code" = l."item_code"
    WHERE  substr(t."txn_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY "year", c."category_name"
)
SELECT w."year",
       w."category_name",
       w."avg_whsle_px",
       w."max_whsle_px",
       w."min_whsle_px",
       w."whsle_px_diff",
       w."total_whsle_px",
       s."total_selling_px",
       l."avg_loss_rate_%"            AS "avg_loss_rate",
       l."total_loss",
       ROUND(s."total_selling_px" - w."total_whsle_px" - l."total_loss", 2) AS "profit"
FROM   whsle_stats w
LEFT   JOIN sales_tot s ON w."year" = s."year" AND w."category_name" = s."category_name"
LEFT   JOIN loss_tot  l ON w."year" = l."year" AND w."category_name" = l."category_name"
ORDER  BY w."year", w."category_name";