WITH wholesale AS (
    SELECT
        strftime('%Y', w."whsle_date")                               AS year,
        c."category_name"                                            AS category,
        AVG(w."whsle_px_rmb-kg")                                     AS avg_wholesale_price,
        MAX(w."whsle_px_rmb-kg")                                     AS max_wholesale_price,
        MIN(w."whsle_px_rmb-kg")                                     AS min_wholesale_price,
        SUM(w."whsle_px_rmb-kg")                                     AS total_wholesale_price
    FROM "veg_whsle_df" w
    JOIN "veg_cat"      c ON w."item_code" = c."item_code"
    WHERE strftime('%Y', w."whsle_date") BETWEEN '2020' AND '2023'
    GROUP BY year, category
),
selling AS (
    SELECT
        strftime('%Y', t."txn_date")                                 AS year,
        c."category_name"                                            AS category,
        SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg")           AS total_selling_price
    FROM "veg_txn_df" t
    JOIN "veg_cat"    c ON t."item_code" = c."item_code"
    WHERE strftime('%Y', t."txn_date") BETWEEN '2020' AND '2023'
    GROUP BY year, category
),
loss AS (
    SELECT
        c."category_name"                                            AS category,
        AVG(l."loss_rate_%")                                         AS avg_loss_rate
    FROM "veg_loss_rate_df" l
    JOIN "veg_cat"         c ON l."item_code" = c."item_code"
    GROUP BY category
)
SELECT
    w.year,
    w.category,
    ROUND(w.avg_wholesale_price , 2)                                 AS avg_wholesale_price,
    ROUND(w.max_wholesale_price , 2)                                 AS max_wholesale_price,
    ROUND(w.min_wholesale_price , 2)                                 AS min_wholesale_price,
    ROUND(w.max_wholesale_price - w.min_wholesale_price, 2)          AS wholesale_price_difference,
    ROUND(w.total_wholesale_price, 2)                                AS total_wholesale_price,
    ROUND(s.total_selling_price, 2)                                  AS total_selling_price,
    ROUND(l.avg_loss_rate, 2)                                        AS avg_loss_rate,
    ROUND(w.total_wholesale_price * l.avg_loss_rate / 100, 2)        AS total_loss,
    ROUND(
        s.total_selling_price
        - w.total_wholesale_price
        - w.total_wholesale_price * l.avg_loss_rate / 100, 2
    )                                                                AS profit
FROM wholesale w
JOIN selling  s ON w.year = s.year AND w.category = s.category
JOIN loss     l ON w.category = l.category
ORDER BY w.year,
         w.category;