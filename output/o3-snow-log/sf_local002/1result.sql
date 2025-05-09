WITH toy_products AS (
    /* all products whose translated category contains the word “toy”              */
    SELECT  p."product_id"
    FROM    E_COMMERCE.E_COMMERCE.PRODUCTS                              p
    JOIN    E_COMMERCE.E_COMMERCE.PRODUCT_CATEGORY_NAME_TRANSLATION     t
           ON p."product_category_name" = t."product_category_name"
    WHERE   t."product_category_name_english" ILIKE '%toy%'
),  
toy_order_items AS (
    /* order-item lines that are toys                                            */
    SELECT  oi."order_id",
            oi."price"
    FROM    E_COMMERCE.E_COMMERCE.ORDER_ITEMS  oi
    JOIN    toy_products                       tp  ON oi."product_id" = tp."product_id"
),  
toy_orders AS (
    /* delivered orders (to be able to date them)                                */
    SELECT  "order_id",
            DATE("order_purchase_timestamp") AS "order_date"
    FROM    E_COMMERCE.E_COMMERCE.ORDERS 
    WHERE   "order_status" = 'delivered'
),  
toy_sales AS (
    /* DAILY toy sales revenue in the training window 2017-01-01 … 2018-08-29    */
    SELECT  o."order_date",
            SUM(oi."price")                 AS "daily_sales"
    FROM    toy_order_items  oi
    JOIN    toy_orders      o   ON oi."order_id" = o."order_id"
    WHERE   o."order_date" BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP BY o."order_date"
),  
indexed_sales AS (
    /* give each training day a sequential index                                 */
    SELECT  "order_date",
            "daily_sales",
            ROW_NUMBER() OVER (ORDER BY "order_date") AS "day_idx"
    FROM    toy_sales
),  
regression_params AS (
    /* simple linear regression parameters                                       */
    SELECT  REGR_SLOPE( "daily_sales", "day_idx")      AS "slope",
            REGR_INTERCEPT("daily_sales", "day_idx")   AS "intercept"
    FROM    indexed_sales
),  
date_series AS (
    /* a calendar from 2017-01-01 through 2018-12-10 (enough for 5-day window)   */
    SELECT  DATEADD(day, seq4(), '2017-01-01') AS "dt"
    FROM    TABLE(GENERATOR(ROWCOUNT => 1100))
    WHERE   DATEADD(day, seq4(), '2017-01-01') <= '2018-12-10'
),  
predicted_sales AS (
    /* predicted toy sales for every day using the regression line               */
    SELECT  ds."dt"                                                            AS "sales_date",
            rp."intercept" + rp."slope" * (DATEDIFF(day, '2017-01-01', ds."dt") + 1)
                                                                               AS "predicted_sales"
    FROM    date_series       ds
    CROSS JOIN regression_params rp
),  
moving_avg AS (
    /* 5-day symmetric moving average of the predictions                         */
    SELECT  "sales_date",
            AVG("predicted_sales") OVER (ORDER BY "sales_date"
                                         ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
                                         AS "ma_5"
    FROM    predicted_sales
)
SELECT  SUM("ma_5") AS "sum_5day_moving_avg_dec5_to_dec8_2018"
FROM    moving_avg
WHERE   "sales_date" BETWEEN '2018-12-05' AND '2018-12-08';