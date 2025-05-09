WITH
    avg_wholesale_prices AS (
        SELECT
            w."item_code",
            strftime('%Y', w."whsle_date") AS "Year",
            AVG(w."whsle_px_rmb-kg") AS "Avg_Wholesale_Price",
            MAX(w."whsle_px_rmb-kg") AS "Max_Wholesale_Price",
            MIN(w."whsle_px_rmb-kg") AS "Min_Wholesale_Price"
        FROM
            "veg_whsle_df" w
        WHERE
            w."whsle_date" BETWEEN '2020-01-01' AND '2023-12-31'
        GROUP BY
            w."item_code", "Year"
    ),
    total_qty_sold AS (
        SELECT
            t."item_code",
            strftime('%Y', t."txn_date") AS "Year",
            SUM(t."qty_sold(kg)") AS "Total_Qty_Sold",
            SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg") AS "Total_Selling_Price"
        FROM
            "veg_txn_df" t
        WHERE
            t."txn_date" BETWEEN '2020-01-01' AND '2023-12-31'
        GROUP BY
            t."item_code", "Year"
    ),
    loss_rate AS (
        SELECT
            l."item_code",
            l."loss_rate_%"
        FROM
            "veg_loss_rate_df" l
    ),
    combined AS (
        SELECT
            t."item_code",
            t."Year",
            t."Total_Qty_Sold",
            t."Total_Selling_Price",
            a."Avg_Wholesale_Price",
            a."Max_Wholesale_Price",
            a."Min_Wholesale_Price",
            l."loss_rate_%"
        FROM
            total_qty_sold t
            LEFT JOIN avg_wholesale_prices a ON t."item_code" = a."item_code" AND t."Year" = a."Year"
            LEFT JOIN loss_rate l ON t."item_code" = l."item_code"
    )
SELECT
    c."Year",
    cat."category_name" AS "Category",
    ROUND(AVG(c."Avg_Wholesale_Price"), 2) AS "Average_Wholesale_Price",
    ROUND(MAX(c."Max_Wholesale_Price"), 2) AS "Maximum_Wholesale_Price",
    ROUND(MIN(c."Min_Wholesale_Price"), 2) AS "Minimum_Wholesale_Price",
    ROUND(MAX(c."Max_Wholesale_Price") - MIN(c."Min_Wholesale_Price"), 2) AS "Wholesale_Price_Difference",
    ROUND(SUM(COALESCE(c."Avg_Wholesale_Price" * c."Total_Qty_Sold", 0)), 2) AS "Total_Wholesale_Price",
    ROUND(SUM(c."Total_Selling_Price"), 2) AS "Total_Selling_Price",
    ROUND(AVG(c."loss_rate_%"), 2) AS "Average_Loss_Rate",
    ROUND(SUM(COALESCE(c."Total_Qty_Sold" * c."loss_rate_%" / 100, 0)), 2) AS "Total_Loss",
    ROUND(SUM(c."Total_Selling_Price") - SUM(COALESCE(c."Avg_Wholesale_Price" * c."Total_Qty_Sold", 0)), 2) AS "Profit"
FROM
    combined c
    INNER JOIN "veg_cat" cat ON c."item_code" = cat."item_code"
WHERE
    c."Year" BETWEEN '2020' AND '2023'
GROUP BY
    c."Year", "Category"
ORDER BY
    c."Year", "Category";