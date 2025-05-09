WITH whsle_stats AS (          /* 1. price‑level statistics per category & year */
    SELECT
        vc.category_name                               AS category,
        CAST(strftime('%Y', vw.whsle_date) AS INTEGER) AS yr,
        ROUND(AVG(vw."whsle_px_rmb-kg"), 2)            AS avg_wholesale_price,
        ROUND(MAX(vw."whsle_px_rmb-kg"), 2)            AS max_wholesale_price,
        ROUND(MIN(vw."whsle_px_rmb-kg"), 2)            AS min_wholesale_price
    FROM veg_whsle_df        vw
    JOIN veg_cat             vc  ON vc.item_code = vw.item_code
    WHERE CAST(strftime('%Y', vw.whsle_date) AS INTEGER) BETWEEN 2020 AND 2023
    GROUP BY vc.category_name,
             yr
),
sale_stats AS (            /* 2. value‑level metrics (cost, revenue, loss, …) */
    SELECT
        vc.category_name                               AS category,
        CAST(strftime('%Y', vt.txn_date) AS INTEGER)   AS yr,
        ROUND(SUM(vt."qty_sold(kg)" * vw."whsle_px_rmb-kg"), 2)                       AS total_wholesale_price,
        ROUND(SUM(vt."qty_sold(kg)" * vt."unit_selling_px_rmb/kg"), 2)                AS total_selling_price,
        ROUND(AVG(COALESCE(vl."loss_rate_%", 0)), 2)                                   AS avg_loss_rate,
        ROUND(SUM(vt."qty_sold(kg)" * vw."whsle_px_rmb-kg"
                  * COALESCE(vl."loss_rate_%", 0) / 100.0), 2)                        AS total_loss
    FROM veg_txn_df          vt
    JOIN veg_whsle_df        vw  ON vw.item_code = vt.item_code
                                AND substr(vw.whsle_date,1,10) = substr(vt.txn_date,1,10)
    JOIN veg_cat             vc  ON vc.item_code = vt.item_code
    LEFT JOIN veg_loss_rate_df vl ON vl.item_code = vt.item_code
    WHERE CAST(strftime('%Y', vt.txn_date) AS INTEGER) BETWEEN 2020 AND 2023
    GROUP BY vc.category_name,
             yr
),
combined AS (              /* 3. merge the two result sets & derive finals */
    SELECT
        ws.category                                  AS category_name,
        ws.yr                                        AS year,
        ws.avg_wholesale_price,
        ws.max_wholesale_price,
        ws.min_wholesale_price,
        ROUND(ws.max_wholesale_price - ws.min_wholesale_price, 2)  AS wholesale_price_difference,
        ss.total_wholesale_price,
        ss.total_selling_price,
        ss.avg_loss_rate,
        ss.total_loss,
        ROUND(ss.total_selling_price 
             - ss.total_wholesale_price 
             - ss.total_loss, 2)                                      AS profit
    FROM whsle_stats ws
    LEFT JOIN sale_stats ss
           ON ss.category = ws.category
          AND ss.yr       = ws.yr
)
SELECT *
FROM combined
ORDER BY year,
         category_name;