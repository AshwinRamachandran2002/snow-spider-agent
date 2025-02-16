-- Task: For veg whsle data, can you analyze our financial performance for the year 2023? I need insights into the average wholesale price, maximum wholesale price, minimum wholesale price, wholesale price difference, total wholesale price, total selling price, and average loss rate for each category within the year. Round all calculated values to two decimal places.
WITH item_2023 AS (
    SELECT
        TO_CHAR(TO_DATE(v."txn_date", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY') AS yr,
        c."category_code",
        c."category_name",
        ROUND(AVG(w."whsle_px_rmb-kg"), 2) AS avg_whole_sale,
        ROUND(MAX(w."whsle_px_rmb-kg"), 2) AS max_whole_sale,
        ROUND(MIN(w."whsle_px_rmb-kg"), 2) AS min_whole_sale,
        ROUND(MAX(w."whsle_px_rmb-kg") - MIN(w."whsle_px_rmb-kg"), 2) AS whole_sale_diff,
        ROUND(SUM(v."qty_sold(kg)" * w."whsle_px_rmb-kg"), 2) AS whole_sale_price,
        ROUND(SUM(v."unit_selling_px_rmb/kg" * v."qty_sold(kg)"), 2) AS selling_price,
        ROUND(AVG(alr."loss_rate_%"), 2) AS avg_loss_rate_pct
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_TXN_DF" v
    LEFT JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_WHSLE_DF" w 
        ON v."txn_date" = w."whsle_date" AND v."item_code" = w."item_code"
    LEFT JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_CAT" c 
        ON v."item_code" = c."item_code"
    LEFT JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_LOSS_RATE_DF" alr 
        ON alr."item_code" = v."item_code"
    WHERE v."qty_sold(kg)" > 0 AND TO_CHAR(TO_DATE(v."txn_date", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY') = '2023'
    GROUP BY yr, c."category_code", c."category_name"
)
SELECT * FROM item_2023;