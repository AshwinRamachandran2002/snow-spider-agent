WITH base AS (
    /*--------------------------------------------------------------------
      Bring together, for every sale line, its wholesale price, loss‐rate
      and category. Keep only years 2020‑2023.
    --------------------------------------------------------------------*/
    SELECT
        strftime('%Y', t."txn_date")                           AS year,
        c."category_name",
        t."item_code",
        t."qty_sold(kg)"                                       AS qty_sold,
        t."unit_selling_px_rmb/kg"                             AS sell_px,
        w."whsle_px_rmb-kg"                                    AS whsle_px,
        COALESCE(l."loss_rate_%",0)                            AS loss_rate
    FROM   veg_txn_df                 AS t
    JOIN   veg_whsle_df               AS w  ON w."item_code" = t."item_code"
                                            AND date(w."whsle_date") = date(t."txn_date")
    JOIN   veg_cat                    AS c  ON c."item_code" = t."item_code"
    LEFT   JOIN veg_loss_rate_df      AS l  ON l."item_code" = t."item_code"
    WHERE  t."sale/return" = 'sale'
      AND  strftime('%Y', t."txn_date") BETWEEN '2020' AND '2023'
), yearly_cat_finance AS (
    /*--------------------------------------------------------------------
      Aggregate required financial metrics for each category & year.
    --------------------------------------------------------------------*/
    SELECT
        year,
        category_name,
        ROUND(AVG(whsle_px)                      , 2) AS avg_wholesale_price,
        ROUND(MAX(whsle_px)                      , 2) AS max_wholesale_price,
        ROUND(MIN(whsle_px)                      , 2) AS min_wholesale_price,
        ROUND(MAX(whsle_px) - MIN(whsle_px)      , 2) AS wholesale_price_diff,
        ROUND(SUM(whsle_px * qty_sold)           , 2) AS total_wholesale_price,
        ROUND(SUM(sell_px  * qty_sold)           , 2) AS total_selling_price,
        ROUND(AVG(loss_rate)                     , 2) AS avg_loss_rate,
        ROUND(SUM((loss_rate/100.0) * whsle_px * qty_sold), 2) AS total_loss,
        ROUND(SUM(sell_px * qty_sold) 
              - SUM(whsle_px * qty_sold) 
              - SUM((loss_rate/100.0) * whsle_px * qty_sold), 2) AS profit
    FROM   base
    GROUP  BY year, category_name
)
SELECT *
FROM   yearly_cat_finance
ORDER  BY year, category_name;