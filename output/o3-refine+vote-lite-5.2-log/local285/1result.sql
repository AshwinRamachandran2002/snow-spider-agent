WITH txns AS (
    SELECT
        CAST(strftime('%Y', vt."txn_date") AS INTEGER)          AS year,
        COALESCE(vc."category_name", 'Unknown')                 AS category_name,
        vw."whsle_px_rmb-kg"                                    AS whsle_px,
        COALESCE(vl."loss_rate_%", 0)                           AS loss_rate,
        vt."qty_sold(kg)"                                       AS qty,
        vt."unit_selling_px_rmb/kg"                             AS sell_px,
        vt."qty_sold(kg)" * vt."unit_selling_px_rmb/kg"         AS selling_price,
        vt."qty_sold(kg)" * vw."whsle_px_rmb-kg"                AS wholesale_cost,
        (vt."qty_sold(kg)" * vt."unit_selling_px_rmb/kg")
             * COALESCE(vl."loss_rate_%", 0) / 100.0            AS loss_value
    FROM  veg_txn_df                vt
    JOIN  veg_whsle_df              vw  ON  vw."item_code" = vt."item_code"
                                       AND date(vw."whsle_date") = date(vt."txn_date")
    LEFT JOIN veg_cat               vc  ON  vc."item_code" = vt."item_code"
    LEFT JOIN veg_loss_rate_df      vl  ON  vl."item_code" = vt."item_code"
    WHERE vt."sale/return" = 'sale'
      AND CAST(strftime('%Y', vt."txn_date") AS INTEGER) BETWEEN 2020 AND 2023
),
agg AS (
    SELECT
        year,
        category_name,
        ROUND(AVG(whsle_px), 2)                                   AS avg_wholesale_price,
        ROUND(MAX(whsle_px), 2)                                   AS max_wholesale_price,
        ROUND(MIN(whsle_px), 2)                                   AS min_wholesale_price,
        ROUND(MAX(whsle_px) - MIN(whsle_px), 2)                   AS wholesale_price_difference,
        ROUND(SUM(wholesale_cost), 2)                             AS total_wholesale_price,
        ROUND(SUM(selling_price), 2)                              AS total_selling_price,
        ROUND(AVG(loss_rate), 2)                                  AS avg_loss_rate,
        ROUND(SUM(loss_value), 2)                                 AS total_loss,
        ROUND(SUM(selling_price) - SUM(wholesale_cost) 
              - SUM(loss_value), 2)                               AS profit
    FROM txns
    GROUP BY year, category_name
)
SELECT *
FROM agg
ORDER BY year, category_name;