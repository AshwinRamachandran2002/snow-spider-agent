WITH
-- 1. quantity & revenue per item‑year (sales only)
txn AS (
    SELECT
        item_code,
        SUBSTR("txn_date",1,4)         AS year,
        SUM("qty_sold(kg)")            AS qty_kg,
        SUM("qty_sold(kg)" * "unit_selling_px_rmb/kg") AS revenue
    FROM veg_txn_df
    WHERE "sale/return" = 'sale'
      AND SUBSTR("txn_date",1,4) BETWEEN '2020' AND '2023'
    GROUP BY item_code, year
),
-- 2. average wholesale price per item‑year
wh AS (
    SELECT
        item_code,
        SUBSTR("whsle_date",1,4)       AS year,
        AVG("whsle_px_rmb-kg")         AS avg_whsle_price
    FROM veg_whsle_df
    WHERE SUBSTR("whsle_date",1,4) BETWEEN '2020' AND '2023'
    GROUP BY item_code, year
),
-- 3. loss rate per item
loss AS (
    SELECT
        item_code,
        "loss_rate_%" AS loss_rate
    FROM veg_loss_rate_df
),
-- 4. category lookup
cat AS (
    SELECT
        item_code,
        category_name
    FROM veg_cat
),
-- 5. detailed finance numbers per category‑year
finance AS (
    SELECT
        t.year,
        c.category_name,
        SUM(t.qty_kg * w.avg_whsle_price)              AS total_wholesale_price,
        SUM(t.revenue)                                 AS total_selling_price,
        AVG(l.loss_rate)                               AS average_loss_rate,
        SUM(t.revenue * (l.loss_rate/100.0))           AS total_loss
    FROM txn t
    JOIN wh   w   ON w.item_code = t.item_code AND w.year = t.year
    JOIN loss l   ON l.item_code = t.item_code
    JOIN cat  c   ON c.item_code = t.item_code
    GROUP BY t.year, c.category_name
),
-- 6. wholesale price statistics (avg/max/min) per category‑year
wh_stats AS (
    SELECT
        SUBSTR(w."whsle_date",1,4)                     AS year,
        c.category_name,
        AVG(w."whsle_px_rmb-kg")                       AS average_wholesale_price,
        MAX(w."whsle_px_rmb-kg")                       AS max_wholesale_price,
        MIN(w."whsle_px_rmb-kg")                       AS min_wholesale_price
    FROM veg_whsle_df w
    JOIN veg_cat    c ON c.item_code = w.item_code
    WHERE SUBSTR(w."whsle_date",1,4) BETWEEN '2020' AND '2023'
    GROUP BY year, c.category_name
)

SELECT
    ws.year                                                    AS year,
    ws.category_name                                           AS category,
    ROUND(ws.average_wholesale_price,2)                        AS average_wholesale_price,
    ROUND(ws.max_wholesale_price,2)                            AS max_wholesale_price,
    ROUND(ws.min_wholesale_price,2)                            AS min_wholesale_price,
    ROUND(ws.max_wholesale_price - ws.min_wholesale_price,2)   AS wholesale_price_difference,
    ROUND(f.total_wholesale_price,2)                           AS total_wholesale_price,
    ROUND(f.total_selling_price,2)                             AS total_selling_price,
    ROUND(f.average_loss_rate,2)                               AS average_loss_rate,
    ROUND(f.total_loss,2)                                      AS total_loss,
    ROUND(f.total_selling_price - f.total_wholesale_price - f.total_loss,2) AS profit
FROM wh_stats ws
JOIN finance  f
  ON f.year = ws.year AND f.category_name = ws.category_name
ORDER BY ws.year, ws.category_name;