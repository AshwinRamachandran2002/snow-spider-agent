WITH daily_sales AS (
    /* daily toy sales from 2017‑01‑01 to 2018‑08‑29 */
    SELECT DATE(o.order_purchase_timestamp)                           AS dt,
           SUM(oi.price)                                              AS sales
    FROM   orders                             o
    JOIN   order_items                        oi ON oi.order_id = o.order_id
    JOIN   products                           p  ON p.product_id = oi.product_id
    JOIN   product_category_name_translation  t  ON t.product_category_name = p.product_category_name
    WHERE  t.product_category_name_english = 'toys'
      AND  DATE(o.order_purchase_timestamp) BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP  BY dt
),
stats AS (
    /* aggregates needed for simple linear regression */
    SELECT COUNT(*)                                                                  AS n,
           SUM(julianday(dt) - julianday('2017-01-01'))                              AS sum_x,
           SUM(sales)                                                                AS sum_y,
           SUM( (julianday(dt) - julianday('2017-01-01')) *
                (julianday(dt) - julianday('2017-01-01')) )                          AS sum_x2,
           SUM( (julianday(dt) - julianday('2017-01-01')) * sales )                  AS sum_xy
    FROM   daily_sales
),
coefficients AS (
    /* slope and intercept of the line:  y = intercept + slope * x */
    SELECT (n*sum_xy - sum_x*sum_y) * 1.0 / (n*sum_x2 - sum_x*sum_x)                 AS slope,
           (sum_y - ((n*sum_xy - sum_x*sum_y) * 1.0 / (n*sum_x2 - sum_x*sum_x)) *
            sum_x) / n                                                               AS intercept
    FROM   stats
),
calendar AS (
    /* calendar from 2018‑12‑03 to 2018‑12‑10 */
    SELECT DATE('2018-12-03') AS dt
    UNION ALL
    SELECT DATE(dt,'+1 day')  FROM calendar WHERE dt < '2018-12-10'
),
predictions AS (
    /* predicted toy sales for each day in calendar using the regression line */
    SELECT c.dt,
           co.intercept + co.slope * (julianday(c.dt) - julianday('2017-01-01')) AS pred_sales
    FROM   calendar      c
    CROSS  JOIN coefficients co
),
centers AS (
    /* the center dates we care about */
    SELECT dt FROM calendar WHERE dt BETWEEN '2018-12-05' AND '2018-12-08'
),
moving_avg AS (
    /* 5‑day symmetric moving average (±2 days) around each center date */
    SELECT ce.dt                                  AS center_date,
           AVG(pr.pred_sales)                     AS five_day_avg
    FROM   centers      ce
    JOIN   predictions  pr
           ON pr.dt BETWEEN DATE(ce.dt,'-2 day') AND DATE(ce.dt,'+2 day')
    GROUP  BY ce.dt
)
SELECT SUM(five_day_avg) AS sum_of_four_moving_averages
FROM   moving_avg;