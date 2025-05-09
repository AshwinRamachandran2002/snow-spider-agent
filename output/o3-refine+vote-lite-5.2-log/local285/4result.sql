WITH whsle_item_year AS (   -- average wholesale price per item & year
    SELECT
        "item_code",
        strftime('%Y', "whsle_date")   AS year,
        AVG("whsle_px_rmb-kg")         AS avg_whsle_px
    FROM veg_whsle_df
    WHERE strftime('%Y', "whsle_date") BETWEEN '2020' AND '2023'
    GROUP BY "item_code",
             year
),
whsle_cat_year AS (         -- avg / max / min wholesale price per category & year
    SELECT
        c."category_name",
        wiy.year,
        AVG(wiy.avg_whsle_px)          AS avg_whsle_price,
        MAX(wiy.avg_whsle_px)          AS max_whsle_price,
        MIN(wiy.avg_whsle_px)          AS min_whsle_price
    FROM whsle_item_year  wiy
    JOIN veg_cat          c
          ON wiy."item_code" = c."item_code"
    GROUP BY c."category_name",
             wiy.year
),
txn_with_cost AS (          -- each sale with its wholesale cost
    SELECT
        t."item_code",
        strftime('%Y', t."txn_date")            AS year,
        t."qty_sold(kg)"                        AS qty,
        t."qty_sold(kg)" * t."unit_selling_px_rmb/kg"      AS selling_value,
        t."qty_sold(kg)" * wiy.avg_whsle_px                 AS wholesale_value
    FROM veg_txn_df        t
    JOIN whsle_item_year   wiy
         ON  t."item_code"             = wiy."item_code"
         AND strftime('%Y', t."txn_date") = wiy.year
    WHERE t."sale/return" = 'sale'
      AND strftime('%Y', t."txn_date") BETWEEN '2020' AND '2023'
),
sales_cost_cat_year AS (    -- total selling & wholesale price per category & year
    SELECT
        c."category_name",
        twc.year,
        SUM(twc.wholesale_value)       AS total_wholesale_price,
        SUM(twc.selling_value)         AS total_selling_price
    FROM txn_with_cost   twc
    JOIN veg_cat         c
         ON twc."item_code" = c."item_code"
    GROUP BY c."category_name",
             twc.year
),
loss_cat_year AS (          -- average loss rate & total loss value per category & year
    SELECT
        c."category_name",
        twc.year,
        AVG(l."loss_rate_%")                                   AS avg_loss_rate,
        SUM(twc.wholesale_value * (l."loss_rate_%"/100.0))     AS total_loss
    FROM txn_with_cost     twc
    JOIN veg_loss_rate_df  l
         ON twc."item_code" = l."item_code"
    JOIN veg_cat           c
         ON twc."item_code" = c."item_code"
    GROUP BY c."category_name",
             twc.year
)
SELECT
    w."category_name"                             AS category,
    w.year,
    ROUND(w.avg_whsle_price, 2)                   AS avg_wholesale_price,
    ROUND(w.max_whsle_price, 2)                   AS max_wholesale_price,
    ROUND(w.min_whsle_price, 2)                   AS min_wholesale_price,
    ROUND(w.max_whsle_price - w.min_whsle_price, 2) AS wholesale_price_difference,
    ROUND(s.total_wholesale_price, 2)             AS total_wholesale_price,
    ROUND(s.total_selling_price, 2)               AS total_selling_price,
    ROUND(l.avg_loss_rate, 2)                     AS avg_loss_rate,
    ROUND(l.total_loss, 2)                        AS total_loss,
    ROUND(s.total_selling_price
          - s.total_wholesale_price
          - l.total_loss, 2)                      AS profit
FROM   whsle_cat_year       w
JOIN   sales_cost_cat_year  s  ON w."category_name" = s."category_name"
                               AND w.year           = s.year
JOIN   loss_cat_year        l  ON w."category_name" = l."category_name"
                               AND w.year           = l.year
ORDER BY w.year,
         w."category_name";