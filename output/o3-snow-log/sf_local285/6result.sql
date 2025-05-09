/*--------------------------------------------------------------------
 Financial performance of vegetable wholesale business
 for each category (2020-2023)
--------------------------------------------------------------------*/
WITH cat AS (   /* item → category map */
    SELECT
        "item_code",
        "category_name"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_CAT"
),

/*------------------- WHOLESALE PRICES ------------------------------*/
whsle AS (
    SELECT
        c."category_name",
        YEAR(TO_DATE(w."whsle_date"))          AS sale_year,
        w."whsle_px_rmb-kg"                    AS whsle_px
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_WHSLE_DF" w
    JOIN cat c
      ON w."item_code" = c."item_code"
    WHERE YEAR(TO_DATE(w."whsle_date")) BETWEEN 2020 AND 2023
),
whsle_agg AS (
    SELECT
        "category_name",
        sale_year,
        ROUND(AVG(whsle_px),2)                            AS avg_wholesale_price,
        ROUND(MAX(whsle_px),2)                            AS max_wholesale_price,
        ROUND(MIN(whsle_px),2)                            AS min_wholesale_price,
        ROUND(MAX(whsle_px) - MIN(whsle_px),2)            AS wholesale_price_difference,
        ROUND(SUM(whsle_px),2)                            AS total_wholesale_price
    FROM whsle
    GROUP BY "category_name", sale_year
),

/*------------------- LOSS RATES (static) ---------------------------*/
loss_rate AS (
    SELECT
        c."category_name",
        ROUND(AVG(l."loss_rate_%"),2)  AS avg_loss_rate          -- %
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_LOSS_RATE_DF" l
    JOIN cat c
      ON l."item_code" = c."item_code"
    GROUP BY c."category_name"
),

/*------------------- SALES (revenue) -------------------------------*/
txn AS (
    SELECT
        c."category_name",
        YEAR(TO_DATE(t."txn_date"))                            AS sale_year,
        SUM(   t."qty_sold(kg)"
             * t."unit_selling_px_rmb/kg"
             * t."discount(%)" )                              AS total_selling_price_raw
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_TXN_DF" t
    JOIN cat c
      ON t."item_code" = c."item_code"
    WHERE LOWER(t."sale/return") = 'sale'
      AND YEAR(TO_DATE(t."txn_date")) BETWEEN 2020 AND 2023
    GROUP BY c."category_name", YEAR(TO_DATE(t."txn_date"))
),
txn_agg AS (
    SELECT
        "category_name",
        sale_year,
        ROUND(total_selling_price_raw,2)  AS total_selling_price
    FROM txn
)

/*------------------- FINAL REPORT ---------------------------------*/
SELECT
    w."category_name",
    w.sale_year                                       AS year,
    w.avg_wholesale_price,
    w.max_wholesale_price,
    w.min_wholesale_price,
    w.wholesale_price_difference,
    w.total_wholesale_price,
    t.total_selling_price,
    l.avg_loss_rate,
    /* total loss = wholesale cost × loss-rate% */
    ROUND(w.total_wholesale_price * l.avg_loss_rate/100, 2) AS total_loss,
    /* profit = revenue – cost – loss */
    ROUND(
          COALESCE(t.total_selling_price, 0)
        - w.total_wholesale_price
        - w.total_wholesale_price * l.avg_loss_rate/100
    , 2) AS profit
FROM whsle_agg w
LEFT JOIN txn_agg  t ON w."category_name" = t."category_name"
                    AND w.sale_year       = t.sale_year
LEFT JOIN loss_rate l ON w."category_name" = l."category_name"
ORDER BY w."category_name", w.sale_year;