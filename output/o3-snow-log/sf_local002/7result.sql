/*-----------------------------------------------------------
   1.  Build the training set: daily toy‐category sales
       from 2017-01-01 to 2018-08-29
 -----------------------------------------------------------*/
WITH training_data AS (
    SELECT
        TO_DATE(o."order_purchase_timestamp")                    AS sales_date ,
        SUM(oi."price")                                          AS sales,
        DATEDIFF(day,'2017-01-01',TO_DATE(o."order_purchase_timestamp")) AS t
    FROM  E_COMMERCE.E_COMMERCE.ORDERS                       o
    JOIN  E_COMMERCE.E_COMMERCE.ORDER_ITEMS                  oi ON oi."order_id" = o."order_id"
    JOIN  E_COMMERCE.E_COMMERCE.PRODUCTS                     p  ON p."product_id" = oi."product_id"
    JOIN  E_COMMERCE.E_COMMERCE.PRODUCT_CATEGORY_NAME_TRANSLATION tr
           ON tr."product_category_name" = p."product_category_name"
    /* toy categories */
    WHERE tr."product_category_name_english" ILIKE '%toy%'       -- covers 'toys'
      AND o."order_purchase_timestamp" >= '2017-01-01'
      AND o."order_purchase_timestamp" <= '2018-08-29'
    GROUP BY TO_DATE(o."order_purchase_timestamp")
),

/*-----------------------------------------------------------
   2.  Derive simple-linear-regression parameters
 -----------------------------------------------------------*/
model_stats AS (
    SELECT
        REGR_SLOPE(sales, t)      AS slope ,
        REGR_INTERCEPT(sales, t)  AS intercept
    FROM training_data
),

/*-----------------------------------------------------------
   3.  Produce a full daily calendar up to 2018-12-10
       (we need dates two days after 8-Dec)
 -----------------------------------------------------------*/
calendar AS (
    SELECT DATEADD(day, SEQ4(), '2017-01-01') AS dt
    FROM TABLE(GENERATOR(ROWCOUNT => 800))            -- 800 >  (2018-12-10 – 2017-01-01)
),

/*-----------------------------------------------------------
   4.  Predict daily toy sales with the fitted model
 -----------------------------------------------------------*/
predicted_sales AS (
    SELECT
        c.dt                                                               AS sales_date ,
        ms.intercept + ms.slope * DATEDIFF(day,'2017-01-01',c.dt)          AS predicted_sales
    FROM calendar            c
    CROSS JOIN model_stats    ms
),

/*-----------------------------------------------------------
   5.  5-day symmetric moving average (2 days before & after)
 -----------------------------------------------------------*/
moving_avg AS (
    SELECT
        sales_date ,
        AVG(predicted_sales)
            OVER (ORDER BY sales_date
                  ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)  AS ma_5d
    FROM predicted_sales
    WHERE sales_date BETWEEN '2018-12-03' AND '2018-12-10'   -- keep window support days
),

/*-----------------------------------------------------------
   6.  Keep the four target days and sum their 5-day MAs
 -----------------------------------------------------------*/
target_days AS (
    SELECT sales_date, ma_5d
    FROM   moving_avg
    WHERE  sales_date BETWEEN '2018-12-05' AND '2018-12-08'
)

SELECT
    SUM(ma_5d) AS sum_of_5day_moving_averages
FROM target_days;