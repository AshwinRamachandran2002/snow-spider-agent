WITH whsle AS (
    SELECT
        w."item_code",
        c."category_name",
        DATE(SUBSTR(w."whsle_date",1,10))                       AS day,
        CAST(STRFTIME('%Y', SUBSTR(w."whsle_date",1,10)) AS INT) AS year,
        w."whsle_px_rmb-kg"                                     AS whsle_px,
        COALESCE(lr."loss_rate_%",0)                            AS loss_rate
    FROM veg_whsle_df w
    JOIN veg_cat               c  ON w."item_code" = c."item_code"
    LEFT JOIN veg_loss_rate_df lr ON w."item_code" = lr."item_code"
    WHERE CAST(STRFTIME('%Y', SUBSTR(w."whsle_date",1,10)) AS INT) BETWEEN 2020 AND 2023
),
sales AS (
    SELECT
        t."item_code",
        c."category_name",
        DATE(SUBSTR(t."txn_date",1,10))                        AS day,
        CAST(STRFTIME('%Y', SUBSTR(t."txn_date",1,10)) AS INT) AS year,
        t."qty_sold(kg)"                                       AS qty,
        t."unit_selling_px_rmb/kg"                             AS sell_px
    FROM veg_txn_df t
    JOIN veg_cat c ON t."item_code" = c."item_code"
    WHERE t."sale/return" = 'sale'
      AND CAST(STRFTIME('%Y', SUBSTR(t."txn_date",1,10)) AS INT) BETWEEN 2020 AND 2023
),
combined AS (
    SELECT
        s.year,
        s.category_name,
        s.item_code,
        s.qty,
        s.sell_px,
        s.qty * s.sell_px                               AS total_selling,
        COALESCE(w.whsle_px,0)                          AS whsle_px,
        s.qty * COALESCE(w.whsle_px,0)                  AS total_whsle,
        COALESCE(w.loss_rate,0)                         AS loss_rate,
        (s.qty * COALESCE(w.whsle_px,0)) * (COALESCE(w.loss_rate,0)/100.0) AS loss_cost
    FROM sales s
    LEFT JOIN whsle w
      ON s.item_code = w.item_code
     AND s.day       = w.day
)
SELECT
    year,
    category_name,
    ROUND(AVG(whsle_px),2)                              AS avg_wholesale_price,
    ROUND(MAX(whsle_px),2)                              AS max_wholesale_price,
    ROUND(MIN(whsle_px),2)                              AS min_wholesale_price,
    ROUND(MAX(whsle_px) - MIN(whsle_px),2)              AS wholesale_price_difference,
    ROUND(SUM(total_whsle),2)                           AS total_wholesale_price,
    ROUND(SUM(total_selling),2)                         AS total_selling_price,
    ROUND(AVG(loss_rate),2)                             AS avg_loss_rate,
    ROUND(SUM(loss_cost),2)                             AS total_loss,
    ROUND(SUM(total_selling) - SUM(total_whsle) - SUM(loss_cost),2) AS profit
FROM combined
GROUP BY year, category_name
ORDER BY year, category_name;