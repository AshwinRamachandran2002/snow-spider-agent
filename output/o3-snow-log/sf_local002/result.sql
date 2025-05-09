WITH toy_categories AS (   -- 1. categories whose English name contains “toy”
    SELECT "product_category_name"
    FROM   E_COMMERCE.E_COMMERCE.PRODUCT_CATEGORY_NAME_TRANSLATION
    WHERE  LOWER("product_category_name_english") LIKE '%toy%'
), toy_products AS (       -- 2. all toy products
    SELECT "product_id"
    FROM   E_COMMERCE.E_COMMERCE.PRODUCTS
    WHERE  "product_category_name" IN (SELECT "product_category_name" FROM toy_categories)
), daily_sales AS (        -- 3. daily toy sales 2017-01-01 … 2018-08-29
    SELECT
        CAST(TO_TIMESTAMP(o."order_purchase_timestamp") AS DATE)   AS sales_date,
        SUM(oi."price")                                           AS sales
    FROM   E_COMMERCE.E_COMMERCE.ORDER_ITEMS  oi
    JOIN   E_COMMERCE.E_COMMERCE.ORDERS       o  ON o."order_id" = oi."order_id"
    JOIN   toy_products                       tp ON tp."product_id" = oi."product_id"
    WHERE  o."order_purchase_timestamp" >= '2017-01-01'
      AND  o."order_purchase_timestamp" <= '2018-08-29'
    GROUP BY CAST(TO_TIMESTAMP(o."order_purchase_timestamp") AS DATE)
), regression_params AS (  -- 4. simple linear regression parameters
    SELECT
        REGR_SLOPE(sales, day_num)      AS slope,
        REGR_INTERCEPT(sales, day_num)  AS intercept
    FROM (
        SELECT
            sales,
            DATEDIFF('day', '2017-01-01'::date, sales_date) AS day_num
        FROM   daily_sales
    )
), pred_dates AS (         -- 5. dates 2018-12-03 … 2018-12-10
    SELECT DATEADD('day', SEQ4(), '2018-12-03'::date) AS pred_date
    FROM   TABLE(GENERATOR(ROWCOUNT => 8))
), predictions AS (        -- predicted sales for each date
    SELECT
        p.pred_date,
        r.intercept
        + r.slope * DATEDIFF('day','2017-01-01'::date, p.pred_date) AS predicted_sales
    FROM   pred_dates         p
    CROSS  JOIN regression_params r
), moving_avg AS (         -- 6. five-day symmetric moving average
    SELECT
        p1.pred_date,
        AVG(p2.predicted_sales) AS ma5
    FROM   predictions p1
    JOIN   predictions p2
           ON ABS(DATEDIFF('day', p1.pred_date, p2.pred_date)) <= 2   -- ±2 days
    GROUP BY p1.pred_date
)
SELECT
    ROUND(SUM(ma5), 4) AS total_5day_ma_sum      -- 7. sum of MA for 12-05 … 12-08
FROM   moving_avg
WHERE  pred_date BETWEEN '2018-12-05' AND '2018-12-08';