WITH toy_sales AS (
    /* daily quantity of items whose category is translated as 'toys'                       */
    SELECT
        DATE(o.order_purchase_timestamp)              AS sale_date,
        COUNT(*)                                       AS sales_qty
    FROM   orders                           AS o
    JOIN   order_items                      AS oi ON oi.order_id  = o.order_id
    JOIN   products                         AS p  ON p.product_id = oi.product_id
    JOIN   product_category_name_translation AS t  ON t.product_category_name = p.product_category_name
    WHERE  t.product_category_name_english = 'toys'
      AND  DATE(o.order_purchase_timestamp) BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP  BY sale_date
),
/* prepare x (days since 2017‑01‑01) and y (sales) for the regression                      */
xy AS (
    SELECT
        CAST(julianday(sale_date) - julianday('2017-01-01') AS REAL)  AS x,
        CAST(sales_qty                                       AS REAL) AS y
    FROM   toy_sales
),
/* aggregate terms needed for simple‑linear‑regression coefficients                        */
reg AS (
    SELECT
        COUNT(*)               AS n,
        SUM(x)                 AS sum_x,
        SUM(y)                 AS sum_y,
        SUM(x*x)               AS sum_x2,
        SUM(x*y)               AS sum_xy
    FROM   xy
),
coeff AS (
    /* slope and intercept */
    SELECT
        (n*sum_xy - sum_x*sum_y)        / (n*sum_x2 - sum_x*sum_x)     AS slope,
        (sum_y - ((n*sum_xy - sum_x*sum_y) / (n*sum_x2 - sum_x*sum_x))
                 * sum_x) / n                                            AS intercept
    FROM   reg
),
/* calendar dates we must predict for: to build 5‑day windows centred on Dec‑05 … Dec‑08   */
future_dates AS (
    SELECT DATE('2018-12-03') AS d UNION ALL
    SELECT DATE('2018-12-04') UNION ALL
    SELECT DATE('2018-12-05') UNION ALL
    SELECT DATE('2018-12-06') UNION ALL
    SELECT DATE('2018-12-07') UNION ALL
    SELECT DATE('2018-12-08') UNION ALL
    SELECT DATE('2018-12-09') UNION ALL
    SELECT DATE('2018-12-10')
),
/* predicted daily toy sales for each future date                                          */
predictions AS (
    SELECT
        d                                                         AS pred_date,
        intercept + slope * (julianday(d) - julianday('2017-01-01'))  AS pred_sales
    FROM   future_dates, coeff
),
/* 5‑day symmetric moving average centred on each required date                            */
moving_avg AS (
    SELECT
        centre.center_date,
        AVG(pred.pred_sales)  AS five_day_ma
    FROM (
        SELECT DATE('2018-12-05') AS center_date UNION ALL
        SELECT DATE('2018-12-06') UNION ALL
        SELECT DATE('2018-12-07') UNION ALL
        SELECT DATE('2018-12-08')
    ) AS centre
    JOIN predictions AS pred
      ON julianday(pred.pred_date) 
         BETWEEN julianday(centre.center_date, '-2 days')
         AND     julianday(centre.center_date, '+2 days')
    GROUP BY centre.center_date
),
/* sum of the four required 5‑day moving averages                                          */
final_sum AS (
    SELECT SUM(five_day_ma) AS sum_of_mas
    FROM   moving_avg
)
SELECT sum_of_mas
FROM   final_sum;