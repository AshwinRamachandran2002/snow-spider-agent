WITH training_daily_sales AS (          -- 1. Daily toy-item sales 2017-01-01 … 2018-08-29
    SELECT 
        CAST(o."order_purchase_timestamp" AS DATE)                AS "order_date",
        COUNT(*)                                                  AS "daily_sales"
    FROM E_COMMERCE.E_COMMERCE."ORDER_ITEMS"  oi
    JOIN E_COMMERCE.E_COMMERCE."PRODUCTS"     p  ON p."product_id" = oi."product_id"
    JOIN E_COMMERCE.E_COMMERCE."PRODUCT_CATEGORY_NAME_TRANSLATION" t
                                               ON t."product_category_name" = p."product_category_name"
    JOIN E_COMMERCE.E_COMMERCE."ORDERS"       o  ON o."order_id"   = oi."order_id"
    WHERE LOWER(t."product_category_name_english") LIKE '%toy%'          -- toys
      AND CAST(o."order_purchase_timestamp" AS DATE) BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP BY CAST(o."order_purchase_timestamp" AS DATE)
),                                          -- 2. Regression parameters
regression_params AS (
    SELECT 
        REGR_SLOPE(   "daily_sales", "date_number")     AS "slope",
        REGR_INTERCEPT("daily_sales", "date_number")     AS "intercept"
    FROM (
        SELECT 
            "daily_sales",
            DATEDIFF('day','1970-01-01'::DATE, "order_date") AS "date_number"
        FROM training_daily_sales
    )
),                                          -- 3. Calendar 2018-11-30 … 2018-12-10
future_calendar AS (
    SELECT DATEADD('day', SEQ4(), '2018-11-30'::DATE) AS "dt"
    FROM TABLE(GENERATOR(ROWCOUNT => 11))                             -- constant rowcount
),                                          -- 4. Predicted toy sales
predicted_sales AS (
    SELECT 
        fc."dt",
        rp."intercept" + rp."slope" * DATEDIFF('day','1970-01-01'::DATE, fc."dt") AS "predicted_sales"
    FROM future_calendar fc
    CROSS JOIN regression_params rp
),                                          -- 5. 5-day symmetric moving average
five_day_moving_avg AS (
    SELECT 
        "dt",
        AVG("predicted_sales") OVER(ORDER BY "dt" 
                                    ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS "ma_5day"
    FROM predicted_sales
)
-- 6. Sum of the four required moving averages (2018-12-05 … 2018-12-08)
SELECT 
    ROUND(SUM("ma_5day"), 4) AS "sum_4day_5day_moving_avgs"
FROM five_day_moving_avg
WHERE "dt" BETWEEN '2018-12-05' AND '2018-12-08';