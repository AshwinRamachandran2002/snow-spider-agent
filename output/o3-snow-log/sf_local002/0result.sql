/*--------------------------------------------------------------------
  1.  Build the training set: daily toy sales from 2017-01-01 to 2018-08-29
----------------------------------------------------------------------*/
WITH training_sales AS (
    SELECT
        DATE_TRUNC('day', TO_DATE(o."order_purchase_timestamp"))       AS sales_date,
        SUM(oi."price")                                                AS daily_sales,
        DATEDIFF('day', '2017-01-01', DATE_TRUNC('day', TO_DATE(o."order_purchase_timestamp"))) AS day_num
    FROM  "E_COMMERCE"."E_COMMERCE"."ORDERS"              o
    JOIN  "E_COMMERCE"."E_COMMERCE"."ORDER_ITEMS"         oi  ON oi."order_id" = o."order_id"
    JOIN  "E_COMMERCE"."E_COMMERCE"."PRODUCTS"            p   ON p."product_id" = oi."product_id"
    LEFT JOIN "E_COMMERCE"."E_COMMERCE"."PRODUCT_CATEGORY_NAME_TRANSLATION" t
           ON t."product_category_name" = p."product_category_name"
    WHERE (t."product_category_name_english" = 'toys' OR p."product_category_name" = 'brinquedos')
      AND o."order_purchase_timestamp" >= '2017-01-01'
      AND o."order_purchase_timestamp" <= '2018-08-29'
    GROUP BY 1
),

/*--------------------------------------------------------------------
  2.  Derive simple-linear-regression parameters (slope & intercept)
----------------------------------------------------------------------*/
lr_coeffs AS (
    SELECT
        REGR_SLOPE(daily_sales, day_num)      AS slope,
        REGR_INTERCEPT(daily_sales, day_num)  AS intercept
    FROM training_sales
),

/*--------------------------------------------------------------------
  3.  Create the future date range that we’ll need (2018-12-03 … 2018-12-10)
----------------------------------------------------------------------*/
future_dates AS (
    SELECT 
        DATEADD(day, seq4(), '2018-12-03') AS pred_date
    FROM TABLE(GENERATOR(ROWCOUNT => 8))      -- produces 8 rows: 2018-12-03 … 2018-12-10
),

/*--------------------------------------------------------------------
  4.  Predict toy sales for each future date with the LR model
----------------------------------------------------------------------*/
predictions AS (
    SELECT
        fd.pred_date,
        lc.intercept + lc.slope * DATEDIFF('day', '2017-01-01', fd.pred_date) AS predicted_sales
    FROM future_dates fd
    CROSS JOIN lr_coeffs lc
),

/*--------------------------------------------------------------------
  5.  5-day symmetric moving average of the predicted sales
----------------------------------------------------------------------*/
predictions_ma AS (
    SELECT
        pred_date,
        AVG(predicted_sales) OVER (ORDER BY pred_date 
                                   ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS ma_5day
    FROM predictions
)

/*--------------------------------------------------------------------
  6.  Sum of the 5-day moving averages for 2018-12-05 … 2018-12-08
----------------------------------------------------------------------*/
SELECT 
    ROUND(SUM(ma_5day), 4)  AS total_of_5day_moving_averages
FROM predictions_ma
WHERE pred_date BETWEEN '2018-12-05' AND '2018-12-08';