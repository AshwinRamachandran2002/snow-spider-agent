WITH wholesale AS (
    SELECT
        c."category_name",
        EXTRACT(YEAR FROM TO_TIMESTAMP(w."whsle_date", 'YYYY-MM-DD HH24:MI:SS')) AS "Year",
        AVG(w."whsle_px_rmb-kg") AS "avg_wholesale_price",
        MAX(w."whsle_px_rmb-kg") AS "max_wholesale_price",
        MIN(w."whsle_px_rmb-kg") AS "min_wholesale_price",
        MAX(w."whsle_px_rmb-kg") - MIN(w."whsle_px_rmb-kg") AS "price_difference",
        SUM(w."whsle_px_rmb-kg") AS "total_wholesale_price"
    FROM
        "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_WHSLE_DF" w
        JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_CAT" c
            ON w."item_code" = c."item_code"
    WHERE
        EXTRACT(YEAR FROM TO_TIMESTAMP(w."whsle_date", 'YYYY-MM-DD HH24:MI:SS')) BETWEEN 2020 AND 2023
    GROUP BY
        c."category_name",
        EXTRACT(YEAR FROM TO_TIMESTAMP(w."whsle_date", 'YYYY-MM-DD HH24:MI:SS'))
),
sales AS (
    SELECT
        c."category_name",
        EXTRACT(YEAR FROM TO_TIMESTAMP(t."txn_date", 'YYYY-MM-DD HH24:MI:SS')) AS "Year",
        SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg") AS "total_selling_price"
    FROM
        "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_TXN_DF" t
        JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_CAT" c
            ON t."item_code" = c."item_code"
    WHERE
        t."sale/return" = 'sale'
        AND EXTRACT(YEAR FROM TO_TIMESTAMP(t."txn_date", 'YYYY-MM-DD HH24:MI:SS')) BETWEEN 2020 AND 2023
    GROUP BY
        c."category_name",
        EXTRACT(YEAR FROM TO_TIMESTAMP(t."txn_date", 'YYYY-MM-DD HH24:MI:SS'))
),
loss_rate AS (
    SELECT
        c."category_name",
        AVG(l."loss_rate_%") AS "avg_loss_rate"
    FROM
        "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_LOSS_RATE_DF" l
        JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_CAT" c
            ON l."item_code" = c."item_code"
    GROUP BY
        c."category_name"
)
SELECT
    w."category_name" AS "Category_Name",
    w."Year",
    ROUND(w."avg_wholesale_price", 4) AS "Avg_Wholesale_Price",
    ROUND(w."max_wholesale_price", 4) AS "Max_Wholesale_Price",
    ROUND(w."min_wholesale_price", 4) AS "Min_Wholesale_Price",
    ROUND(w."price_difference", 4) AS "Wholesale_Price_Diff",
    ROUND(w."total_wholesale_price", 4) AS "Total_Wholesale_Price",
    ROUND(s."total_selling_price", 4) AS "Total_Selling_Price",
    ROUND(COALESCE(l."avg_loss_rate", 0), 4) AS "Avg_Loss_Rate",
    ROUND(w."total_wholesale_price" * COALESCE(l."avg_loss_rate", 0) / 100, 4) AS "Total_Loss",
    ROUND(s."total_selling_price" - w."total_wholesale_price" - (w."total_wholesale_price" * COALESCE(l."avg_loss_rate", 0) / 100), 4) AS "Profit"
FROM
    wholesale w
    LEFT JOIN sales s ON w."category_name" = s."category_name" AND w."Year" = s."Year"
    LEFT JOIN loss_rate l ON w."category_name" = l."category_name"
ORDER BY
    w."category_name",
    w."Year";