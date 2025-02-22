-- Task: Using the 'VEG_TXN_DF', 'VEG_WHSLE_DF', 'VEG_CAT', and 'VEG_LOSS_RATE_DF' tables in the 'BANK_SALES_TRADING' database and schema, analyze the financial performance for vegetable wholesale data from the years 2020 to 2023. For each category within each year, compute the following metrics:
-- - Average wholesale price
-- - Maximum wholesale price
-- - Minimum wholesale price
-- - Wholesale price difference (maximum - minimum)
-- - Total wholesale price (calculated as the sum of quantity sold multiplied by wholesale price)
-- - Total selling price (calculated as the sum of unit selling price multiplied by quantity sold)
-- - Average loss rate percentage
-- - Total loss (calculated as (average loss rate percentage * total wholesale price) / 100)
-- - Profit (calculated as total selling price minus total wholesale price minus total loss)
-- Ensure that all calculated values are rounded to two decimal places.

WITH item_2020 AS (
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
    WHERE v."qty_sold(kg)" > 0 AND TO_CHAR(TO_DATE(v."txn_date", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY') = '2020'
    GROUP BY TO_CHAR(TO_DATE(v."txn_date", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY'), c."category_code", c."category_name"
),
item_2021 AS (
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
    WHERE v."qty_sold(kg)" > 0 AND TO_CHAR(TO_DATE(v."txn_date", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY') = '2021'
    GROUP BY TO_CHAR(TO_DATE(v."txn_date", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY'), c."category_code", c."category_name"
),
item_2022 AS (
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
    WHERE v."qty_sold(kg)" > 0 AND TO_CHAR(TO_DATE(v."txn_date", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY') = '2022'
    GROUP BY TO_CHAR(TO_DATE(v."txn_date", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY'), c."category_code", c."category_name"
),
item_2023 AS (
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
    GROUP BY TO_CHAR(TO_DATE(v."txn_date", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY'), c."category_code", c."category_name"
),
final_item AS (
    SELECT * FROM item_2020
    UNION
    SELECT * FROM item_2021
    UNION
    SELECT * FROM item_2022
    UNION
    SELECT * FROM item_2023
)

SELECT *,
    ROUND(((avg_loss_rate_pct * whole_sale_price) / 100.00), 2) AS total_loss,
    ROUND((selling_price - whole_sale_price - ((avg_loss_rate_pct * whole_sale_price) / 100.00)), 2) AS profit
FROM final_item;