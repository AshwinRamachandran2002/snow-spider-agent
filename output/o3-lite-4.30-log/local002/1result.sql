WITH toy_categories AS (
    SELECT "product_category_name"
    FROM   "product_category_name_translation"
    WHERE  "product_category_name_english" = 'toys'
),
-- 1. Daily toy sales used to train the regression
daily_sales AS (
    SELECT DATE(o."order_purchase_timestamp") AS sale_date,
           COUNT(*)                           AS qty
    FROM   "order_items"  oi
    JOIN   "products"     p  ON p."product_id" = oi."product_id"
    JOIN   "orders"       o  ON o."order_id"   = oi."order_id"
    WHERE  p."product_category_name" IN (SELECT * FROM toy_categories)
      AND  DATE(o."order_purchase_timestamp") BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP  BY DATE(o."order_purchase_timestamp")
),
-- 2. Simple‑linear‑regression coefficients
reg_stats AS (
    SELECT COUNT(*) AS n,
           SUM(x)   AS sum_x,
           SUM(y)   AS sum_y,
           SUM(x*y) AS sum_xy,
           SUM(x*x) AS sum_xx
    FROM (
        SELECT (julianday(sale_date) - julianday('2017-01-01')) AS x,
               qty                                              AS y
        FROM   daily_sales
    )
),
params AS (
    SELECT (n*sum_xy - sum_x*sum_y) / (n*sum_xx - sum_x*sum_x)                    AS slope,
           (sum_y - ((n*sum_xy - sum_x*sum_y)/(n*sum_xx - sum_x*sum_x))*sum_x)/n  AS intercept
    FROM   reg_stats
),
-- 3. Prediction dates (need ±2 days around 5‑8 Dec 2018)
forecast_dates AS (
    SELECT DATE('2018-12-03') AS sale_date UNION ALL
    SELECT DATE('2018-12-04') UNION ALL
    SELECT DATE('2018-12-05') UNION ALL
    SELECT DATE('2018-12-06') UNION ALL
    SELECT DATE('2018-12-07') UNION ALL
    SELECT DATE('2018-12-08') UNION ALL
    SELECT DATE('2018-12-09') UNION ALL
    SELECT DATE('2018-12-10')
),
-- 4. Predicted toy sales for each forecast date
predicted AS (
    SELECT fd.sale_date,
           params.slope * (julianday(fd.sale_date) - julianday('2017-01-01'))
           + params.intercept                                   AS predicted_qty
    FROM   forecast_dates fd
    CROSS  JOIN params
),
-- 5. 5‑day symmetric moving average (±2 days) – keep only 05‑08 Dec 2018
moving_avg AS (
    SELECT p1.sale_date,
           AVG(p2.predicted_qty) AS five_day_ma
    FROM   predicted p1
    JOIN   predicted p2
           ON julianday(p2.sale_date) BETWEEN julianday(p1.sale_date,'-2 day')
                                          AND     julianday(p1.sale_date,'+2 day')
    GROUP  BY p1.sale_date
    HAVING p1.sale_date BETWEEN '2018-12-05' AND '2018-12-08'
),
-- 6. Add grand total row
result AS (
    SELECT sale_date, five_day_ma FROM moving_avg
    UNION ALL
    SELECT 'sum', SUM(five_day_ma) FROM moving_avg
)
SELECT sale_date,
       ROUND(five_day_ma,4) AS "5_day_symmetric_moving_average"
FROM   result
ORDER  BY CASE WHEN sale_date = 'sum' THEN 2 ELSE 1 END, sale_date;