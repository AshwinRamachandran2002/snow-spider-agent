WITH
/* 1. Which Portuguese category names correspond to toys?          */
toy_categories AS (
    SELECT DISTINCT product_category_name
    FROM   product_category_name_translation
    WHERE  product_category_name_english LIKE '%toy%'   -- e.g.  'toys'
),

/* 2. Toy sales per day (orders’ purchase date)                     */
toy_sales AS (
    SELECT date(o.order_purchase_timestamp)                AS sale_date,
           COUNT(*)                                        AS qty
    FROM   orders        o
    JOIN   order_items   oi ON oi.order_id  = o.order_id
    JOIN   products      p  ON p.product_id = oi.product_id
    WHERE  p.product_category_name IN (SELECT * FROM toy_categories)
      AND  date(o.order_purchase_timestamp) BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP  BY sale_date
),

/* 3. Complete daily series so we also have “zero–sale” dates       */
daily_series AS (
    WITH  RECURSIVE days(d) AS (
           SELECT date('2017-01-01')
           UNION ALL
           SELECT date(d,'+1 day')
           FROM   days
           WHERE  d < '2018-08-29'
    )
    SELECT d AS sale_date
    FROM   days
),

sales_data AS (
    SELECT ds.sale_date,
           COALESCE(ts.qty,0) AS qty
    FROM   daily_series ds
    LEFT   JOIN toy_sales ts USING (sale_date)
),

/* 4. Prepare X (day index) and Y (qty), then regression statistics */
indexed AS (
    SELECT sale_date,
           qty,
           (julianday(sale_date) - julianday('2017-01-01')) AS x
    FROM   sales_data
),

stats AS (
    SELECT COUNT(*)                          AS n,
           SUM(x*qty)                        AS sum_xy,
           SUM(x)                            AS sum_x,
           SUM(qty)                          AS sum_y,
           SUM(x*x)                          AS sum_x2
    FROM   indexed
),

/* 5. Slope (m) and intercept (b) of simple linear regression       */
coeff AS (
    SELECT
        (n*sum_xy - sum_x*sum_y)                /
        (n*sum_x2 - sum_x*sum_x)            AS m,
        (sum_y - ((n*sum_xy - sum_x*sum_y)  /
        (n*sum_x2 - sum_x*sum_x))*sum_x) / n AS b
    FROM stats
),

/* 6. Predict daily sales from 3‑Dec‑2018 to 10‑Dec‑2018            */
predictions AS (
    SELECT
        date('2018-12-03','+'||i||' day')                       AS pred_date,
        m * (julianday(date('2018-12-03','+'||i||' day')) -
             julianday('2017-01-01')) + b                       AS predicted_qty
    FROM  coeff,
          (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL
           SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
           SELECT 6 UNION ALL SELECT 7) AS offs
),

/* 7. 5‑day symmetric moving average centred on each required day  */
moving_avg AS (
    SELECT p1.pred_date,
           (SELECT AVG(p2.predicted_qty)
            FROM   predictions p2
            WHERE  julianday(p2.pred_date)
                   BETWEEN julianday(p1.pred_date,'-2 day')
                       AND julianday(p1.pred_date,'+2 day')) AS ma5
    FROM   predictions p1
    WHERE  p1.pred_date IN ('2018-12-05','2018-12-06',
                            '2018-12-07','2018-12-08')
)

/* 8. Sum of the four 5‑day moving averages                         */
SELECT SUM(ma5) AS sum_of_5day_moving_averages
FROM   moving_avg;