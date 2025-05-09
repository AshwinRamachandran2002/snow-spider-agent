WITH whsle AS (
    SELECT 
        vc."category_name",
        vw."item_code",
        YEAR(TO_DATE(vw."whsle_date"))          AS yr,
        vw."whsle_px_rmb-kg"                    AS whsle_price
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_WHSLE_DF  vw
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT       vc
          ON vw."item_code" = vc."item_code"
    WHERE YEAR(TO_DATE(vw."whsle_date")) BETWEEN 2020 AND 2023
),
item_year_whsle AS (
    SELECT
        "item_code",
        yr,
        AVG(whsle_price) AS avg_whsle_price
    FROM whsle
    GROUP BY "item_code", yr
),
txn AS (
    SELECT 
        vc."category_name",
        vt."item_code",
        YEAR(TO_DATE(vt."txn_date"))            AS yr,
        vt."qty_sold(kg)"                       AS qty,
        vt."unit_selling_px_rmb/kg"             AS sell_price_perkg
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_TXN_DF    vt
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT       vc
          ON vt."item_code" = vc."item_code"
    WHERE vt."sale/return" = 'sale'
      AND YEAR(TO_DATE(vt."txn_date")) BETWEEN 2020 AND 2023
),
txn_cost AS (
    SELECT
        t."category_name",
        t.yr,
        t."item_code",
        t.qty,
        t.sell_price_perkg,
        COALESCE(i.avg_whsle_price, 0)                        AS avg_whsle_price,
        t.qty * COALESCE(i.avg_whsle_price, 0)                AS total_whsle_cost,
        t.qty * t.sell_price_perkg                            AS total_sell_revenue
    FROM txn t
    LEFT JOIN item_year_whsle i
           ON t."item_code" = i."item_code"
          AND t.yr          = i.yr
),
loss AS (
    SELECT 
        vl."item_code",
        COALESCE(vl."loss_rate_%", 0)/100                     AS loss_rate
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF vl
),
txn_with_loss AS (
    SELECT
        tc."category_name",
        tc.yr,
        tc.qty,
        tc.avg_whsle_price,
        tc.total_whsle_cost,
        tc.total_sell_revenue,
        COALESCE(l.loss_rate, 0)                              AS loss_rate,
        tc.qty * tc.avg_whsle_price * COALESCE(l.loss_rate,0) AS loss_value
    FROM txn_cost tc
    LEFT JOIN loss l
           ON tc."item_code" = l."item_code"
)
SELECT
    twl.yr                                            AS "year",
    twl."category_name"                               AS "category",
    ROUND(AVG(twl.avg_whsle_price), 2)                AS "avg_wholesale_price",
    ROUND(MAX(twl.avg_whsle_price), 2)                AS "max_wholesale_price",
    ROUND(MIN(twl.avg_whsle_price), 2)                AS "min_wholesale_price",
    ROUND(MAX(twl.avg_whsle_price) - 
          MIN(twl.avg_whsle_price), 2)                AS "wholesale_price_difference",
    ROUND(SUM(twl.total_whsle_cost), 2)               AS "total_wholesale_price",
    ROUND(SUM(twl.total_sell_revenue), 2)             AS "total_selling_price",
    ROUND(AVG(twl.loss_rate) * 100, 2)                AS "avg_loss_rate",
    ROUND(SUM(twl.loss_value), 2)                     AS "total_loss",
    ROUND(SUM(twl.total_sell_revenue) 
          - SUM(twl.total_whsle_cost) 
          - SUM(twl.loss_value), 2)                   AS "profit"
FROM txn_with_loss twl
GROUP BY twl.yr, twl."category_name"
ORDER BY twl.yr ASC, twl."category_name"
;