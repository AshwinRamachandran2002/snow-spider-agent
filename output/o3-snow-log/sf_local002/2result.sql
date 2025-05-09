WITH daily AS (   -- 1. daily toy sales between 2017-01-01 and 2018-08-29
    SELECT
        TO_DATE(o."order_purchase_timestamp")                                 AS "order_date",
        COUNT(*)                                                              AS "daily_sales"
    FROM  E_COMMERCE.E_COMMERCE."ORDER_ITEMS"                           oi
    JOIN  E_COMMERCE.E_COMMERCE."ORDERS"                                o  ON oi."order_id" = o."order_id"
    JOIN  E_COMMERCE.E_COMMERCE."PRODUCTS"                              p  ON oi."product_id" = p."product_id"
    JOIN  E_COMMERCE.E_COMMERCE."PRODUCT_CATEGORY_NAME_TRANSLATION"     pct
                                                                           ON p."product_category_name" = pct."product_category_name"
    WHERE pct."product_category_name_english" ILIKE 'toy%'                  -- toy category
      AND TO_DATE(o."order_purchase_timestamp") BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP BY "order_date"
),
daily_with_index AS (   -- 2. add running day index
    SELECT
        "order_date",
        "daily_sales",
        DATEDIFF('day', '2017-01-01'::date, "order_date") AS "day_num"
    FROM daily
),
stats AS (   -- 3. simple linear regression coefficients
    SELECT
        REGR_SLOPE   ("daily_sales", "day_num") AS "slope",
        REGR_INTERCEPT("daily_sales", "day_num") AS "intercept"
    FROM daily_with_index
),
future_dates AS (   -- 4. dates needed for the symmetric 5-day windows (2018-12-03 … 2018-12-10)
    SELECT ('2018-12-03'::date + SEQ4()) AS "the_date"
    FROM TABLE(GENERATOR(ROWCOUNT => 8))   -- 8 rows → 2018-12-03 … 2018-12-10
),
predictions AS (   -- 5. predicted toy sales by linear model
    SELECT
        fd."the_date",
        s."intercept"
        + s."slope" * DATEDIFF('day', '2017-01-01'::date, fd."the_date") AS "predicted_sales"
    FROM future_dates fd
    CROSS JOIN stats s
),
moving_avg AS (   -- 6. 5-day symmetric moving average of the predictions
    SELECT
        "the_date",
        AVG("predicted_sales") OVER (ORDER BY "the_date"
                                     ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS "ma5"
    FROM predictions
)
-- 7. sum of the 5-day moving averages for 05-Dec-2018 to 08-Dec-2018
SELECT
    SUM("ma5") AS "sum_of_5day_moving_avgs"
FROM moving_avg
WHERE "the_date" BETWEEN '2018-12-05' AND '2018-12-08';