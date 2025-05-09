/*----------------------------------------------------
  5-day symmetric moving averages (MA-5) of predicted
  toy sales for 5-Dec-2018 … 8-Dec-2018 and the sum of
  those four MA-5 values
----------------------------------------------------*/
WITH toy_sales AS (   -- daily real sales 2017-01-01 … 2018-08-29
    SELECT
        DATEDIFF(day
                 , '2017-01-01'::DATE
                 , CAST(o."order_purchase_timestamp" AS DATE)
        )                                                 AS "x",
        SUM(oi."price")                                   AS "y"
    FROM  E_COMMERCE.E_COMMERCE."ORDER_ITEMS"            oi
    JOIN  E_COMMERCE.E_COMMERCE."ORDERS"                 o
           ON oi."order_id"  = o."order_id"
    JOIN  E_COMMERCE.E_COMMERCE."PRODUCTS"               p
           ON oi."product_id" = p."product_id"
    JOIN  E_COMMERCE.E_COMMERCE."PRODUCT_CATEGORY_NAME_TRANSLATION" t
           ON p."product_category_name" = t."product_category_name"
    WHERE t."product_category_name_english" = 'toys'
      AND CAST(o."order_purchase_timestamp" AS DATE)
          BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP BY "x"
),
stats AS (            -- regression summary statistics
    SELECT
        COUNT(*)                           AS "n",
        AVG("x")                           AS "avg_x",
        AVG("y")                           AS "avg_y",
        SUM("x" * "y")                     AS "sum_xy",
        SUM("x" * "x")                     AS "sum_x2"
    FROM toy_sales
),
coeff AS (            -- slope & intercept of simple linear regression
    SELECT
        ("sum_xy" - "n" * "avg_x" * "avg_y")
        /
        ("sum_x2" - "n" * "avg_x" * "avg_x")              AS "slope",
        "avg_y"
        -
        ( ("sum_xy" - "n" * "avg_x" * "avg_y")
          /
          ("sum_x2" - "n" * "avg_x" * "avg_x") ) * "avg_x" AS "intercept"
    FROM stats
),
calendar AS (         -- 2018-12-03 … 2018-12-10 (covers all MA-5 windows)
    SELECT
        DATEADD(day, seq4(), '2018-12-03'::DATE) AS "dt"
    FROM TABLE(GENERATOR(ROWCOUNT => 8))                 -- 0 … 7
),
pred AS (             -- predicted toy sales for each calendar date
    SELECT
        "dt",
        "slope" * DATEDIFF(day, '2017-01-01', "dt") + "intercept"
                                                    AS "predicted_sales"
    FROM calendar
    CROSS JOIN coeff
),
mov_avg AS (          -- 5-day symmetric moving average
    SELECT
        "dt",
        AVG("predicted_sales")
            OVER (ORDER BY "dt"
                  ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS "ma5"
    FROM pred
),
target AS (           -- keep only 05-Dec-2018 … 08-Dec-2018
    SELECT "ma5"
    FROM   mov_avg
    WHERE  "dt" BETWEEN '2018-12-05' AND '2018-12-08'
)
SELECT
    SUM("ma5") AS "sum_of_four_5day_moving_averages"
FROM target;