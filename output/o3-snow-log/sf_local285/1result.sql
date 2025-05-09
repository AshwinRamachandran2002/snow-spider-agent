/*  Financial performance of vegetable wholesale & retail
    – yearly view (2020-2023) by vegetable category           */

WITH category_map AS (               -- item → category
    SELECT 
        "item_code",
        "category_name"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT
),

wholesale_prices AS (                -- wholesale price table with year
    SELECT
        "item_code",
        TO_DATE("whsle_date")          AS whsle_dt,
        YEAR(TO_DATE("whsle_date"))    AS yr,
        "whsle_px_rmb-kg"              AS whsle_px
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_WHSLE_DF
    WHERE YEAR(TO_DATE("whsle_date")) BETWEEN 2020 AND 2023
),

wholesale_stats AS (                 -- avg / max / min / diff
    SELECT
        cm."category_name",
        wp.yr                                                     AS year,
        ROUND(AVG(wp.whsle_px)               , 2) AS avg_wholesale_price,
        ROUND(MAX(wp.whsle_px)               , 2) AS max_wholesale_price,
        ROUND(MIN(wp.whsle_px)               , 2) AS min_wholesale_price,
        ROUND(MAX(wp.whsle_px) - MIN(wp.whsle_px), 2) AS wholesale_price_difference
    FROM wholesale_prices      wp
    JOIN category_map          cm ON wp."item_code" = cm."item_code"
    GROUP BY cm."category_name", wp.yr
),

loss_rate_tbl AS (                   -- item → loss rate %
    SELECT
        "item_code",
        COALESCE("loss_rate_%",0) AS loss_rate_pct
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF
),

txn_sales AS (                       -- sales transactions with year
    SELECT
        "item_code",
        TO_DATE("txn_date")               AS txn_dt,
        YEAR(TO_DATE("txn_date"))         AS yr,
        "qty_sold(kg)"                    AS qty,
        "unit_selling_px_rmb/kg"          AS sell_px
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_TXN_DF
    WHERE YEAR(TO_DATE("txn_date")) BETWEEN 2020 AND 2023
      AND "sale/return" = 'sale'
),

txn_financials AS (                  -- cost, revenue, loss per category & year
    SELECT
        cm."category_name",
        ts.yr                                                   AS year,
        SUM(ts.qty * wp.whsle_px)                               AS total_wholesale_price,
        SUM(ts.qty * ts.sell_px)                                AS total_selling_price,
        AVG(lr.loss_rate_pct)                                   AS avg_loss_rate,
        SUM(ts.qty * wp.whsle_px * lr.loss_rate_pct/100)        AS total_loss
    FROM txn_sales          ts
    JOIN wholesale_prices   wp ON ts."item_code" = wp."item_code"
                               AND ts.txn_dt     = wp.whsle_dt
    JOIN category_map       cm ON ts."item_code" = cm."item_code"
    LEFT JOIN loss_rate_tbl lr ON ts."item_code" = lr."item_code"
    GROUP BY cm."category_name", ts.yr
),

final AS (
    SELECT
        ws."category_name",
        ws.year,
        ws.avg_wholesale_price,
        ws.max_wholesale_price,
        ws.min_wholesale_price,
        ws.wholesale_price_difference,
        ROUND(tf.total_wholesale_price , 2) AS total_wholesale_price,
        ROUND(tf.total_selling_price   , 2) AS total_selling_price,
        ROUND(tf.avg_loss_rate         , 2) AS avg_loss_rate,
        ROUND(tf.total_loss            , 2) AS total_loss,
        ROUND(tf.total_selling_price 
                - tf.total_wholesale_price 
                - tf.total_loss            , 2) AS profit
    FROM wholesale_stats ws
    LEFT JOIN txn_financials tf
           ON ws."category_name" = tf."category_name"
          AND ws.year            = tf.year
)

SELECT *
FROM final
ORDER BY year, "category_name";