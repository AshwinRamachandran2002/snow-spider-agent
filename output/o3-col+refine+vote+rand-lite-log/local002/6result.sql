WITH training AS (
    /* daily toy revenue from 2017-01-01 to 2018-08-29 */
    SELECT DATE(o."order_purchase_timestamp")                      AS sale_date,
           SUM(oi."price")                                         AS revenue
    FROM   "orders"        AS o
    JOIN   "order_items"   AS oi ON oi."order_id" = o."order_id"
    JOIN   "products"      AS p  ON p."product_id" = oi."product_id"
    WHERE  p."product_category_name" = 'brinquedos'
      AND  DATE(o."order_purchase_timestamp") BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP  BY sale_date
), stats AS (
    /* aggregates needed for simple linear regression y = a + b*x */
    SELECT COUNT(*)                                           AS n,
           SUM(x)                                             AS sum_x,
           SUM(x*x)                                           AS sum_x2,
           SUM(revenue)                                       AS sum_y,
           SUM(x*revenue)                                     AS sum_xy
    FROM   (
              SELECT revenue,
                     (julianday(sale_date) - julianday('2017-01-01')) AS x
              FROM   training
           )
), coeff AS (
    /* slope (b) and intercept (a) */
    SELECT 
        (n*sum_xy - sum_x*sum_y) * 1.0 / (n*sum_x2 - sum_x*sum_x)     AS slope,
        (sum_y - ((n*sum_xy - sum_x*sum_y) * 1.0 / (n*sum_x2 - sum_x*sum_x))*sum_x) 
        * 1.0 / n                                                    AS intercept
    FROM stats
), future_dates AS (
    /* dates needed for the 5-day windows centred on 5–8 Dec 2018 */
    SELECT DATE('2018-12-03') AS d UNION ALL
    SELECT DATE('2018-12-04') UNION ALL
    SELECT DATE('2018-12-05') UNION ALL
    SELECT DATE('2018-12-06') UNION ALL
    SELECT DATE('2018-12-07') UNION ALL
    SELECT DATE('2018-12-08') UNION ALL
    SELECT DATE('2018-12-09') UNION ALL
    SELECT DATE('2018-12-10')
), predictions AS (
    /* regression-based daily sales prediction for each future date */
    SELECT 
        d                                                     AS pred_date,
        (SELECT intercept FROM coeff) +
        (SELECT slope     FROM coeff) *
        (julianday(d) - julianday('2017-01-01'))              AS pred_sales
    FROM   future_dates
), moving_avg AS (
    /* 5-day symmetric moving average for the central dates */
    SELECT 
        c.pred_date,
        AVG(n.pred_sales)                                     AS ma5
    FROM   predictions  AS c
    JOIN   predictions  AS n
           ON julianday(n.pred_date)
           BETWEEN julianday(c.pred_date, '-2 day') 
               AND julianday(c.pred_date, '+2 day')
    GROUP  BY c.pred_date
    HAVING c.pred_date BETWEEN '2018-12-05' AND '2018-12-08'
)
SELECT SUM(ma5) AS sum_of_moving_averages
FROM   moving_avg;