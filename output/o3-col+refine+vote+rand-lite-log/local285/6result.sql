WITH item_loss_rate AS (               -- average loss-rate % per item
    SELECT "item_code",
           AVG("loss_rate_%") AS avg_loss_rate_pct
    FROM   "veg_loss_rate_df"
    GROUP  BY "item_code"
),
/* 1. wholesale-price statistics (per year & category) */
wholesale_stats AS (
    SELECT substr(vwd."whsle_date",1,4)                        AS year,
           vc."category_name",
           ROUND(AVG(vwd."whsle_px_rmb-kg"),2)                 AS avg_wholesale_price,
           ROUND(MAX(vwd."whsle_px_rmb-kg"),2)                 AS max_wholesale_price,
           ROUND(MIN(vwd."whsle_px_rmb-kg"),2)                 AS min_wholesale_price,
           ROUND(MAX(vwd."whsle_px_rmb-kg") -
                 MIN(vwd."whsle_px_rmb-kg"),2)                 AS wholesale_price_diff
    FROM   "veg_whsle_df"          AS vwd
    JOIN   "veg_cat"               AS vc
           ON vwd."item_code" = vc."item_code"
    WHERE  substr(vwd."whsle_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY year, vc."category_name"
),
/* 2. financial metrics built from sales, wholesale cost & loss */
financials AS (
    SELECT substr(vt."txn_date",1,4)                           AS year,
           vc."category_name",
           ROUND(SUM(vt."qty_sold(kg)" * vwd."whsle_px_rmb-kg"),2)         AS total_wholesale_price,
           ROUND(SUM(vt."qty_sold(kg)" * vt."unit_selling_px_rmb/kg"),2)   AS total_selling_price,
           ROUND(AVG(ilr.avg_loss_rate_pct),2)                               AS avg_loss_rate,
           ROUND(SUM(vt."qty_sold(kg)" * vwd."whsle_px_rmb-kg"
                     * COALESCE(ilr.avg_loss_rate_pct,0)/100.0),2)         AS total_loss,
           ROUND(SUM(vt."qty_sold(kg)" * vt."unit_selling_px_rmb/kg")
                 - SUM(vt."qty_sold(kg)" * vwd."whsle_px_rmb-kg")
                 - SUM(vt."qty_sold(kg)" * vwd."whsle_px_rmb-kg"
                       * COALESCE(ilr.avg_loss_rate_pct,0)/100.0),2)       AS profit
    FROM   "veg_txn_df"               AS vt
    JOIN   "veg_cat"                  AS vc
           ON vt."item_code" = vc."item_code"
    JOIN   "veg_whsle_df"             AS vwd
           ON vt."item_code" = vwd."item_code"
          AND vt."txn_date"  = vwd."whsle_date"
    LEFT   JOIN item_loss_rate        AS ilr
           ON vt."item_code" = ilr."item_code"
    WHERE  vt."sale/return" = 'sale'
      AND  substr(vt."txn_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY year, vc."category_name"
)
/* 3. combine both sets of metrics */
SELECT ws.year,
       ws.category_name,
       ws.avg_wholesale_price,
       ws.max_wholesale_price,
       ws.min_wholesale_price,
       ws.wholesale_price_diff,
       f.total_wholesale_price,
       f.total_selling_price,
       f.avg_loss_rate,
       f.total_loss,
       f.profit
FROM   wholesale_stats AS ws
JOIN   financials      AS f
       USING (year, category_name)
ORDER  BY ws.year,
         ws.category_name;