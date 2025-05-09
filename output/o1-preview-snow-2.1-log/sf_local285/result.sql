WITH
item_sales AS (
    SELECT
        t."item_code",
        c."category_name" AS "Category_Name",
        EXTRACT(YEAR FROM TO_TIMESTAMP(t."txn_date", 'YYYY-MM-DD HH24:MI:SS')) AS "Year",
        SUM(t."qty_sold(kg)") AS "Total_Qty_Sold",
        ROUND(SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg" * (1 - (t."discount(%)" / 100))), 4) AS "Total_Selling_Price"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_TXN_DF" t
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_CAT" c
        ON t."item_code" = c."item_code"
    WHERE t."sale/return" = 'sale'
        AND EXTRACT(YEAR FROM TO_TIMESTAMP(t."txn_date", 'YYYY-MM-DD HH24:MI:SS')) BETWEEN 2020 AND 2023
    GROUP BY t."item_code", c."category_name", EXTRACT(YEAR FROM TO_TIMESTAMP(t."txn_date", 'YYYY-MM-DD HH24:MI:SS'))
),
avg_wholesale_price AS (
    SELECT
        w."item_code",
        c."category_name" AS "Category_Name",
        EXTRACT(YEAR FROM TO_TIMESTAMP(w."whsle_date", 'YYYY-MM-DD HH24:MI:SS')) AS "Year",
        ROUND(AVG(w."whsle_px_rmb-kg"), 4) AS "Avg_Wholesale_Price",
        ROUND(MAX(w."whsle_px_rmb-kg"), 4) AS "Max_Wholesale_Price",
        ROUND(MIN(w."whsle_px_rmb-kg"), 4) AS "Min_Wholesale_Price",
        ROUND(MAX(w."whsle_px_rmb-kg") - MIN(w."whsle_px_rmb-kg"), 4) AS "Wholesale_Price_Diff"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_WHSLE_DF" w
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_CAT" c
        ON w."item_code" = c."item_code"
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(w."whsle_date", 'YYYY-MM-DD HH24:MI:SS')) BETWEEN 2020 AND 2023
    GROUP BY w."item_code", c."category_name", EXTRACT(YEAR FROM TO_TIMESTAMP(w."whsle_date", 'YYYY-MM-DD HH24:MI:SS'))
),
avg_loss_rate AS (
    SELECT
        l."item_code",
        c."category_name" AS "Category_Name",
        ROUND(AVG(l."loss_rate_%"), 4) AS "Avg_Loss_Rate"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_LOSS_RATE_DF" l
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."VEG_CAT" c
        ON l."item_code" = c."item_code"
    GROUP BY l."item_code", c."category_name"
),
item_stats AS (
    SELECT
        s."Category_Name",
        s."Year",
        s."item_code",
        s."Total_Qty_Sold",
        s."Total_Selling_Price",
        awp."Avg_Wholesale_Price",
        awp."Max_Wholesale_Price",
        awp."Min_Wholesale_Price",
        awp."Wholesale_Price_Diff",
        alr."Avg_Loss_Rate",
        ROUND(s."Total_Qty_Sold" * awp."Avg_Wholesale_Price", 4) AS "Total_Wholesale_Price",
        ROUND(s."Total_Qty_Sold" * awp."Avg_Wholesale_Price" * COALESCE(alr."Avg_Loss_Rate", 0) / 100, 4) AS "Total_Loss"
    FROM item_sales s
    LEFT JOIN avg_wholesale_price awp ON s."item_code" = awp."item_code" AND s."Year" = awp."Year" AND s."Category_Name" = awp."Category_Name"
    LEFT JOIN avg_loss_rate alr ON s."item_code" = alr."item_code" AND s."Category_Name" = alr."Category_Name"
),
item_stats_with_profit AS (
    SELECT
        *,
        ROUND("Total_Selling_Price" - "Total_Wholesale_Price" - "Total_Loss", 4) AS "Profit"
    FROM item_stats
),
category_stats AS (
    SELECT
        "Category_Name",
        "Year",
        ROUND(AVG("Avg_Wholesale_Price"), 4) AS "Avg_Wholesale_Price",
        ROUND(MAX("Max_Wholesale_Price"), 4) AS "Max_Wholesale_Price",
        ROUND(MIN("Min_Wholesale_Price"), 4) AS "Min_Wholesale_Price",
        ROUND(MAX("Wholesale_Price_Diff"), 4) AS "Wholesale_Price_Diff",
        ROUND(SUM("Total_Wholesale_Price"), 4) AS "Total_Wholesale_Price",
        ROUND(SUM("Total_Selling_Price"), 4) AS "Total_Selling_Price",
        ROUND(AVG("Avg_Loss_Rate"), 4) AS "Avg_Loss_Rate",
        ROUND(SUM("Total_Loss"), 4) AS "Total_Loss",
        ROUND(SUM("Profit"), 4) AS "Profit"
    FROM item_stats_with_profit
    GROUP BY "Category_Name", "Year"
)
SELECT * FROM category_stats
ORDER BY "Category_Name", "Year";