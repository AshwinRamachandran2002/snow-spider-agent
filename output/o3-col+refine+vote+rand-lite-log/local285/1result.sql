WITH wholesale AS (
    SELECT
        substr(w."whsle_date",1,4)                   AS "year",
        c."category_name",
        AVG(w."whsle_px_rmb-kg")                     AS avg_wholesale_price,
        MAX(w."whsle_px_rmb-kg")                     AS max_wholesale_price,
        MIN(w."whsle_px_rmb-kg")                     AS min_wholesale_price,
        SUM(w."whsle_px_rmb-kg")                     AS total_wholesale_price
    FROM   "veg_whsle_df" AS w
    JOIN   "veg_cat"      AS c USING ("item_code")
    WHERE  substr(w."whsle_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY "year", c."category_name"
),
selling AS (
    SELECT
        substr(t."txn_date",1,4)                     AS "year",
        c."category_name",
        SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg")  AS total_selling_price
    FROM   "veg_txn_df" AS t
    JOIN   "veg_cat"    AS c USING ("item_code")
    WHERE  substr(t."txn_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY "year", c."category_name"
),
loss AS (
    SELECT
        substr(w."whsle_date",1,4)                   AS "year",
        c."category_name",
        AVG(l."loss_rate_%")                         AS avg_loss_rate,
        SUM(w."whsle_px_rmb-kg" * l."loss_rate_%"/100) AS total_loss
    FROM   "veg_whsle_df"     AS w
    JOIN   "veg_loss_rate_df" AS l  USING ("item_code")
    JOIN   "veg_cat"          AS c  USING ("item_code")
    WHERE  substr(w."whsle_date",1,4) BETWEEN '2020' AND '2023'
    GROUP  BY "year", c."category_name"
)

SELECT
    w."year",
    w."category_name",
    ROUND(w.avg_wholesale_price, 2)                       AS avg_wholesale_price,
    ROUND(w.max_wholesale_price, 2)                       AS max_wholesale_price,
    ROUND(w.min_wholesale_price, 2)                       AS min_wholesale_price,
    ROUND(w.max_wholesale_price - w.min_wholesale_price, 2) AS wholesale_price_diff,
    ROUND(w.total_wholesale_price, 2)                     AS total_wholesale_price,
    ROUND(COALESCE(s.total_selling_price, 0), 2)          AS total_selling_price,
    ROUND(COALESCE(l.avg_loss_rate, 0), 2)                AS avg_loss_rate,
    ROUND(COALESCE(l.total_loss, 0), 2)                   AS total_loss,
    ROUND(COALESCE(s.total_selling_price, 0) 
          - w.total_wholesale_price 
          - COALESCE(l.total_loss, 0), 2)                 AS profit
FROM   wholesale AS w
LEFT   JOIN selling AS s
       ON  w."year" = s."year"
       AND w."category_name" = s."category_name"
LEFT   JOIN loss    AS l
       ON  w."year" = l."year"
       AND w."category_name" = l."category_name"
ORDER  BY w."year", w."category_name";