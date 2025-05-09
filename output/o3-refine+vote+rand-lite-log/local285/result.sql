WITH joined AS (
    SELECT
        strftime('%Y', t."txn_date")            AS year,
        c."category_name"                       AS category_name,
        t."qty_sold(kg)"                        AS qty_sold,
        t."unit_selling_px_rmb/kg"              AS selling_price,
        w."whsle_px_rmb-kg"                     AS wholesale_price,
        COALESCE(l."loss_rate_%", 0)            AS loss_rate
    FROM      veg_txn_df              t
    JOIN      veg_whsle_df            w  ON t."item_code" = w."item_code"
                                         AND date(t."txn_date") = date(w."whsle_date")
    JOIN      veg_cat                 c  ON t."item_code" = c."item_code"
    LEFT JOIN veg_loss_rate_df        l  ON t."item_code" = l."item_code"
    WHERE     strftime('%Y', t."txn_date") BETWEEN '2020' AND '2023'
)

SELECT
    year,
    category_name,
    ROUND(AVG(wholesale_price), 2)                                              AS avg_wholesale_price,
    ROUND(MAX(wholesale_price), 2)                                              AS max_wholesale_price,
    ROUND(MIN(wholesale_price), 2)                                              AS min_wholesale_price,
    ROUND(MAX(wholesale_price) - MIN(wholesale_price), 2)                       AS wholesale_price_diff,
    ROUND(SUM(wholesale_price * qty_sold), 2)                                   AS total_wholesale_price,
    ROUND(SUM(selling_price * qty_sold), 2)                                     AS total_selling_price,
    ROUND(AVG(loss_rate), 2)                                                    AS average_loss_rate,
    ROUND(SUM(wholesale_price * qty_sold * loss_rate / 100.0), 2)               AS total_loss,
    ROUND(
        SUM(selling_price * qty_sold)
      - SUM(wholesale_price * qty_sold)
      - SUM(wholesale_price * qty_sold * loss_rate / 100.0), 2)                 AS profit
FROM   joined
GROUP  BY year, category_name
ORDER  BY year, category_name;