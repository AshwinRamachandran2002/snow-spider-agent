WITH "wholesale_stats" AS (
    SELECT 
        c."category_name",
        YEAR(TO_DATE(w."whsle_date"))                         AS "year",
        ROUND(AVG(w."whsle_px_rmb-kg"), 2)                    AS "avg_wholesale_price",
        ROUND(MAX(w."whsle_px_rmb-kg"), 2)                    AS "max_wholesale_price",
        ROUND(MIN(w."whsle_px_rmb-kg"), 2)                    AS "min_wholesale_price",
        ROUND(MAX(w."whsle_px_rmb-kg") 
              - MIN(w."whsle_px_rmb-kg"), 2)                  AS "wholesale_price_difference",
        ROUND(SUM(w."whsle_px_rmb-kg"), 2)                    AS "total_wholesale_price"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_WHSLE_DF" w
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_CAT"      c 
         ON w."item_code" = c."item_code"
    WHERE YEAR(TO_DATE(w."whsle_date")) BETWEEN 2020 AND 2023
    GROUP BY c."category_name",
             YEAR(TO_DATE(w."whsle_date"))
),
"selling_stats" AS (
    SELECT 
        c."category_name",
        YEAR(TO_DATE(t."txn_date"))                           AS "year",
        ROUND(SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg"), 2)
                                                             AS "total_selling_price"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_TXN_DF"  t
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_CAT"      c
         ON t."item_code" = c."item_code"
    WHERE YEAR(TO_DATE(t."txn_date")) BETWEEN 2020 AND 2023
      AND LOWER(t."sale/return") = 'sale'
    GROUP BY c."category_name",
             YEAR(TO_DATE(t."txn_date"))
),
"loss_rates" AS (
    SELECT 
        c."category_name",
        ROUND(AVG(l."loss_rate_%"), 2)                        AS "avg_loss_rate"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_LOSS_RATE_DF" l
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_CAT"      c
         ON l."item_code" = c."item_code"
    GROUP BY c."category_name"
)
SELECT
    w."category_name",
    w."year",
    w."avg_wholesale_price",
    w."max_wholesale_price",
    w."min_wholesale_price",
    w."wholesale_price_difference",
    w."total_wholesale_price",
    COALESCE(s."total_selling_price", 0)                     AS "total_selling_price",
    l."avg_loss_rate",
    ROUND(w."total_wholesale_price" * l."avg_loss_rate" / 100, 2) 
                                                             AS "total_loss",
    ROUND(COALESCE(s."total_selling_price", 0) 
          - w."total_wholesale_price" 
          - (w."total_wholesale_price" * l."avg_loss_rate" / 100), 2) 
                                                             AS "profit"
FROM "wholesale_stats" w
LEFT JOIN "selling_stats" s
       ON w."category_name" = s."category_name"
      AND w."year"          = s."year"
LEFT JOIN "loss_rates"   l
       ON w."category_name" = l."category_name"
ORDER BY w."category_name",
         w."year" NULLS LAST;