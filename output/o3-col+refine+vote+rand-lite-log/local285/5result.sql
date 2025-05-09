WITH sales AS (
    /* yearly quantity sold and selling revenue (only ‘sale’ rows) */
    SELECT substr(vt."txn_date",1,4)                         AS year,
           vc."category_name",
           SUM(vt."qty_sold(kg)")                           AS qty_sold,
           SUM(vt."qty_sold(kg)" * vt."unit_selling_px_rmb/kg") AS total_selling_price
    FROM   "veg_txn_df" vt
    JOIN   "veg_cat"    vc ON vt."item_code" = vc."item_code"
    WHERE  vt."sale/return" = 'sale'
      AND  substr(vt."txn_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY year, vc."category_name"
),
wholesale AS (
    /* yearly wholesale price statistics */
    SELECT substr(vw."whsle_date",1,4) AS year,
           vc."category_name",
           AVG(vw."whsle_px_rmb-kg")   AS avg_wholesale_price,
           MAX(vw."whsle_px_rmb-kg")   AS max_wholesale_price,
           MIN(vw."whsle_px_rmb-kg")   AS min_wholesale_price
    FROM   "veg_whsle_df" vw
    JOIN   "veg_cat"      vc ON vw."item_code" = vc."item_code"
    WHERE  substr(vw."whsle_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY year, vc."category_name"
),
loss AS (
    /* average loss-rate per category (assumed stable through years) */
    SELECT vc."category_name",
           AVG(vl."loss_rate_%") AS avg_loss_rate
    FROM   "veg_loss_rate_df" vl
    JOIN   "veg_cat"          vc ON vl."item_code" = vc."item_code"
    GROUP  BY vc."category_name"
)
SELECT s.year,
       s."category_name",
       ROUND(w.avg_wholesale_price,2)                         AS avg_wholesale_price,
       ROUND(w.max_wholesale_price,2)                         AS max_wholesale_price,
       ROUND(w.min_wholesale_price,2)                         AS min_wholesale_price,
       ROUND(w.max_wholesale_price - w.min_wholesale_price,2) AS wholesale_price_diff,
       ROUND(w.avg_wholesale_price * s.qty_sold,2)            AS total_wholesale_price,
       ROUND(s.total_selling_price,2)                         AS total_selling_price,
       ROUND(l.avg_loss_rate,2)                               AS avg_loss_rate,
       ROUND(s.total_selling_price * l.avg_loss_rate/100.0,2) AS total_loss,
       ROUND(s.total_selling_price
           - (w.avg_wholesale_price * s.qty_sold)
           - (s.total_selling_price * l.avg_loss_rate/100.0),2) AS profit
FROM   sales     s
JOIN   wholesale w ON s.year = w.year
                  AND s."category_name" = w."category_name"
JOIN   loss      l ON s."category_name" = l."category_name"
ORDER BY s.year,
         s."category_name";