WITH whsle AS (
    SELECT
        c."category_name",
        YEAR(TO_DATE(v."whsle_date"))          AS "year",
        v."whsle_px_rmb-kg"                    AS "wholesale_price",
        v."item_code"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_WHSLE_DF          v
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT               c
          ON v."item_code" = c."item_code"
    WHERE YEAR(TO_DATE(v."whsle_date")) BETWEEN 2020 AND 2023
),

whsle_agg AS (
    SELECT
        "category_name",
        "year",
        AVG("wholesale_price")                           AS avg_wholesale,
        MAX("wholesale_price")                           AS max_wholesale,
        MIN("wholesale_price")                           AS min_wholesale,
        SUM("wholesale_price")                           AS total_wholesale
    FROM whsle
    GROUP BY "category_name", "year"
),

selling AS (
    SELECT
        c."category_name",
        YEAR(TO_DATE(t."txn_date"))          AS "year",
        t."unit_selling_px_rmb/kg"           AS "selling_price"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_TXN_DF            t
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT               c
          ON t."item_code" = c."item_code"
    WHERE t."sale/return" = 'sale'
      AND YEAR(TO_DATE(t."txn_date")) BETWEEN 2020 AND 2023
),

selling_agg AS (
    SELECT
        "category_name",
        "year",
        SUM("selling_price")                              AS total_selling
    FROM selling
    GROUP BY "category_name", "year"
),

loss_agg AS (
    SELECT
        w."category_name",
        w."year",
        AVG(l."loss_rate_%")                              AS avg_loss_rate,
        SUM( (COALESCE(l."loss_rate_%",0) / 100) 
               * w."wholesale_price")                     AS total_loss
    FROM whsle                                           w
    LEFT JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF l
           ON w."item_code" = l."item_code"
    GROUP BY w."category_name", w."year"
)

SELECT
    w."category_name",
    w."year",
    ROUND(w.avg_wholesale, 2)                             AS "average_wholesale_price",
    ROUND(w.max_wholesale, 2)                             AS "maximum_wholesale_price",
    ROUND(w.min_wholesale, 2)                             AS "minimum_wholesale_price",
    ROUND(w.max_wholesale - w.min_wholesale, 2)           AS "wholesale_price_difference",
    ROUND(w.total_wholesale, 2)                           AS "total_wholesale_price",
    ROUND(COALESCE(s.total_selling, 0), 2)                AS "total_selling_price",
    ROUND(l.avg_loss_rate, 2)                             AS "average_loss_rate",
    ROUND(l.total_loss, 2)                                AS "total_loss",
    ROUND(COALESCE(s.total_selling, 0) 
          - (w.total_wholesale + l.total_loss), 2)        AS "profit"
FROM whsle_agg  w
LEFT JOIN selling_agg s
       ON w."category_name" = s."category_name"
      AND w."year"          = s."year"
LEFT JOIN loss_agg    l
       ON w."category_name" = l."category_name"
      AND w."year"          = l."year"
ORDER BY w."year", w."category_name";