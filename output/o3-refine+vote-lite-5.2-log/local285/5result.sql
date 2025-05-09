SELECT
    CAST(strftime('%Y', t."txn_date") AS INTEGER)            AS "year",
    c."category_name"                                        AS "category",
    
    /* wholesale price statistics */
    ROUND(AVG(w."whsle_px_rmb-kg"), 2)                       AS "avg_wholesale_price",
    ROUND(MAX(w."whsle_px_rmb-kg"), 2)                       AS "max_wholesale_price",
    ROUND(MIN(w."whsle_px_rmb-kg"), 2)                       AS "min_wholesale_price",
    ROUND(MAX(w."whsle_px_rmb-kg") - MIN(w."whsle_px_rmb-kg"), 2)
                                                             AS "wholesale_price_difference",
    
    /* totals based on quantities sold */
    ROUND(SUM(t."qty_sold(kg)" * w."whsle_px_rmb-kg"), 2)    AS "total_wholesale_price",
    ROUND(SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg"), 2)
                                                             AS "total_selling_price",
    
    /* loss calculations */
    ROUND(AVG(COALESCE(l."loss_rate_%", 0)), 2)              AS "avg_loss_rate_%",    
    ROUND(SUM(t."qty_sold(kg)" * w."whsle_px_rmb-kg"
              * COALESCE(l."loss_rate_%", 0) / 100.0), 2)    AS "total_loss",
    
    /* profit = revenue – cost – loss */
    ROUND(  SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg")
          - SUM(t."qty_sold(kg)" * w."whsle_px_rmb-kg")
          - SUM(t."qty_sold(kg)" * w."whsle_px_rmb-kg"
                 * COALESCE(l."loss_rate_%", 0) / 100.0)
         , 2)                                                AS "profit"
FROM   "veg_txn_df"               AS t
JOIN   "veg_whsle_df"             AS w
       ON  t."item_code" = w."item_code"
       AND date(t."txn_date") = date(w."whsle_date")
JOIN   "veg_cat"                  AS c
       ON  t."item_code" = c."item_code"
LEFT JOIN "veg_loss_rate_df"      AS l
       ON  t."item_code" = l."item_code"
WHERE  CAST(strftime('%Y', t."txn_date") AS INTEGER) BETWEEN 2020 AND 2023
GROUP  BY "year", c."category_name"
ORDER  BY "year", c."category_name";