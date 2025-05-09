WITH whsle AS (   /*  Wholesale price records with category & year  */
    SELECT
        YEAR(TO_DATE("whsle_date"))                          AS year ,
        c."category_name"                                    AS category_name ,
        w."whsle_px_rmb-kg"                                  AS whsle_px
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_WHSLE_DF w
         JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT c
              ON w."item_code" = c."item_code"
    WHERE YEAR(TO_DATE("whsle_date")) BETWEEN 2020 AND 2023
),

/*  Aggregate wholesale-price statistics  */
whsle_aggr AS (
    SELECT
        year ,
        category_name ,
        ROUND(AVG(whsle_px) , 2)                             AS avg_wholesale_price ,
        ROUND(MAX(whsle_px) , 2)                             AS max_wholesale_price ,
        ROUND(MIN(whsle_px) , 2)                             AS min_wholesale_price ,
        ROUND(MAX(whsle_px) - MIN(whsle_px) , 2)             AS wholesale_price_diff ,
        ROUND(SUM(whsle_px) , 2)                             AS total_wholesale_price
    FROM whsle
    GROUP BY year , category_name
),

/*  Selling-price (revenue) detail  */
sell AS (
    SELECT
        YEAR(TO_DATE("txn_date"))                            AS year ,
        c."category_name"                                    AS category_name ,
        ( t."qty_sold(kg)" * t."unit_selling_px_rmb/kg" )    AS selling_value
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_TXN_DF t
         JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT c
              ON t."item_code" = c."item_code"
    WHERE t."sale/return" = 'sale'
      AND YEAR(TO_DATE("txn_date")) BETWEEN 2020 AND 2023
),

/*  Aggregate revenue (total selling price) */
sell_aggr AS (
    SELECT
        year ,
        category_name ,
        ROUND(SUM(selling_value) , 2)                       AS total_selling_price
    FROM sell
    GROUP BY year , category_name
),

/*  Loss-rate information joined with year so we can average per year-category */
loss_data AS (
    SELECT
        YEAR(TO_DATE(w."whsle_date"))                        AS year ,
        c."category_name"                                    AS category_name ,
        l."loss_rate_%"                                      AS loss_rate
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_WHSLE_DF w
         JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT c
              ON w."item_code" = c."item_code"
         JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF l
              ON w."item_code" = l."item_code"
    WHERE YEAR(TO_DATE(w."whsle_date")) BETWEEN 2020 AND 2023
),

/*  Average loss-rate per year-category  */
loss_aggr AS (
    SELECT
        year ,
        category_name ,
        ROUND(AVG(loss_rate) , 2)                           AS avg_loss_rate
    FROM loss_data
    GROUP BY year , category_name
),

/*  Combine wholesale, selling & loss data  */
wh_sell AS (
    SELECT
        COALESCE(w.year , s.year)            AS year ,
        COALESCE(w.category_name , s.category_name) AS category_name ,
        w.avg_wholesale_price ,
        w.max_wholesale_price ,
        w.min_wholesale_price ,
        w.wholesale_price_diff ,
        w.total_wholesale_price ,
        s.total_selling_price
    FROM whsle_aggr w
         FULL OUTER JOIN sell_aggr s
           ON w.year = s.year
          AND w.category_name = s.category_name
),

wh_sell_loss AS (
    SELECT
        ws.* ,
        l.avg_loss_rate
    FROM wh_sell ws
         LEFT JOIN loss_aggr l
           ON ws.year = l.year
          AND ws.category_name = l.category_name
)

/*  Final output with total-loss & profit calculations  */
SELECT
    year ,
    category_name ,
    avg_wholesale_price ,
    max_wholesale_price ,
    min_wholesale_price ,
    wholesale_price_diff ,
    total_wholesale_price ,
    total_selling_price ,
    avg_loss_rate ,
    ROUND( NVL(total_wholesale_price , 0) * NVL(avg_loss_rate , 0) / 100 , 2)  AS total_loss ,
    ROUND( NVL(total_selling_price , 0)
           - NVL(total_wholesale_price , 0)
           - NVL(total_wholesale_price , 0) * NVL(avg_loss_rate , 0) / 100 , 2) AS profit
FROM wh_sell_loss
ORDER BY year , category_name NULLS LAST;