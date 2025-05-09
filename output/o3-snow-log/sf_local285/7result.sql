WITH item_info AS (
    SELECT
        c."item_code",
        c."category_name",
        COALESCE(l."loss_rate_%",0) AS loss_rate_pct
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT                c
    LEFT JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF  l
           ON c."item_code" = l."item_code"
),
/* 1. WHOLESALE-PRICE DESCRIPTIVES */
wholesale_stats AS (
    SELECT
        EXTRACT(YEAR FROM TO_DATE(w."whsle_date"))          AS yr,
        i."category_name"                                   AS category,
        ROUND(AVG(w."whsle_px_rmb-kg"),2)                   AS avg_whsle_price,
        ROUND(MAX(w."whsle_px_rmb-kg"),2)                   AS max_whsle_price,
        ROUND(MIN(w."whsle_px_rmb-kg"),2)                   AS min_whsle_price,
        ROUND(MAX(w."whsle_px_rmb-kg") - 
              MIN(w."whsle_px_rmb-kg"),2)                   AS whsle_price_diff
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_WHSLE_DF w
    JOIN item_info i
      ON w."item_code" = i."item_code"
    WHERE EXTRACT(YEAR FROM TO_DATE(w."whsle_date")) BETWEEN 2020 AND 2023
    GROUP BY yr, category
),
/* 2. SALES, COST, LOSS & PROFIT */
sales_stats AS (
    SELECT
        EXTRACT(YEAR FROM TO_DATE(t."txn_date"))                     AS yr,
        i."category_name"                                            AS category,
        ROUND(SUM(t."qty_sold(kg)" * w."whsle_px_rmb-kg"),2)         AS total_whsle_price,
        ROUND(SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg"),2)  AS total_sell_price,
        ROUND(AVG(i.loss_rate_pct),2)                                AS avg_loss_rate,
        ROUND(SUM(t."qty_sold(kg)" * w."whsle_px_rmb-kg" * 
                  i.loss_rate_pct / 100),2)                          AS total_loss
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_TXN_DF   t
    JOIN item_info                                          i
      ON t."item_code" = i."item_code"
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_WHSLE_DF w
      ON t."item_code"   = w."item_code"
     AND TO_DATE(t."txn_date") = TO_DATE(w."whsle_date")          -- match same-day cost
    WHERE t."sale/return" = 'sale'
      AND EXTRACT(YEAR FROM TO_DATE(t."txn_date")) BETWEEN 2020 AND 2023
    GROUP BY yr, category
)
/* 3. COMBINE & CALCULATE PROFIT */
SELECT
    s.yr                                                AS "year",
    s.category                                          AS "category_name",
    w.avg_whsle_price                                   AS "avg_wholesale_price",
    w.max_whsle_price                                   AS "max_wholesale_price",
    w.min_whsle_price                                   AS "min_wholesale_price",
    w.whsle_price_diff                                  AS "wholesale_price_difference",
    s.total_whsle_price                                 AS "total_wholesale_price",
    s.total_sell_price                                  AS "total_selling_price",
    s.avg_loss_rate                                     AS "avg_loss_rate",
    s.total_loss                                        AS "total_loss",
    ROUND(s.total_sell_price - s.total_whsle_price 
          - s.total_loss, 2)                            AS "profit"
FROM sales_stats     s
LEFT JOIN wholesale_stats w
       ON  s.yr       = w.yr
       AND s.category = w.category
ORDER BY s.yr, s.category;