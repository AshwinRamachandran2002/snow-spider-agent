WITH
/* 1.  Wholesale-price statistics per category & calendar year */
wh_stats AS (
    SELECT
        strftime('%Y', "whsle_date")              AS "year",
        vc."category_name",
        AVG("whsle_px_rmb-kg")                    AS avg_wh,
        MAX("whsle_px_rmb-kg")                    AS max_wh,
        MIN("whsle_px_rmb-kg")                    AS min_wh
    FROM veg_whsle_df  vw
    JOIN veg_cat       vc  ON vw."item_code" = vc."item_code"
    WHERE strftime('%Y', "whsle_date") BETWEEN '2020' AND '2023'
    GROUP BY "year", vc."category_name"
),

/* 2.  Sales-side figures (quantity, selling revenue, wholesale cost) */
sales AS (
    SELECT
        strftime('%Y', vt."txn_date")                         AS "year",
        vc."category_name",
        SUM(vt."qty_sold(kg)")                               AS qty_kg,
        SUM(vt."qty_sold(kg)" * vt."unit_selling_px_rmb/kg") AS sell_total,
        SUM(vt."qty_sold(kg)" * vw."whsle_px_rmb-kg")        AS wh_cost
    FROM veg_txn_df   vt
    JOIN veg_whsle_df vw
         ON vt."item_code" = vw."item_code"
        AND vt."txn_date"  = vw."whsle_date"
    JOIN veg_cat      vc  ON vt."item_code" = vc."item_code"
    WHERE strftime('%Y', vt."txn_date") BETWEEN '2020' AND '2023'
    GROUP BY "year", vc."category_name"
),

/* 3.  Average loss-rate (%) per category */
loss_rates AS (
    SELECT
        vc."category_name",
        AVG(vl."loss_rate_%") AS avg_loss_rate
    FROM veg_loss_rate_df vl
    JOIN veg_cat          vc  ON vl."item_code" = vc."item_code"
    GROUP BY vc."category_name"
)

/* 4.  Combine everything and compute final financial metrics */
SELECT
    s."year",
    s."category_name",
    ROUND(w.avg_wh , 2)                                     AS avg_wholesale_price,
    ROUND(w.max_wh , 2)                                     AS max_wholesale_price,
    ROUND(w.min_wh , 2)                                     AS min_wholesale_price,
    ROUND(w.max_wh - w.min_wh, 2)                           AS wholesale_price_diff,
    ROUND(s.wh_cost   , 2)                                  AS total_wholesale_cost,
    ROUND(s.sell_total, 2)                                  AS total_selling_price,
    ROUND(l.avg_loss_rate, 2)                               AS avg_loss_rate_percent,
    ROUND(s.sell_total * l.avg_loss_rate / 100, 2)          AS total_loss,
    ROUND(s.sell_total - s.wh_cost
          - s.sell_total * l.avg_loss_rate / 100, 2)        AS profit
FROM   sales      s
JOIN   wh_stats   w  ON w."year" = s."year"
                     AND w."category_name" = s."category_name"
JOIN   loss_rates l  ON l."category_name" = s."category_name"
ORDER  BY s."year", s."category_name";