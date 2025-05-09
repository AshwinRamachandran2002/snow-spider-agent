WITH toy_product_ids AS (
    SELECT p.product_id
    FROM products           AS p
    JOIN product_category_name_translation AS t
          ON p.product_category_name = t.product_category_name
    WHERE t.product_category_name_english = 'toys'
), daily_sales AS (
    SELECT DATE(o.order_purchase_timestamp)     AS sale_date,
           COUNT(*)                             AS qty
    FROM orders        AS o
    JOIN order_items   AS oi  ON oi.order_id = o.order_id
    JOIN toy_product_ids      ON toy_product_ids.product_id = oi.product_id
    WHERE DATE(o.order_purchase_timestamp) BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP BY sale_date
), stats AS (
    SELECT CAST(julianday(sale_date) - julianday('2017-01-01') AS REAL) AS x,
           qty
    FROM daily_sales
), agg AS (
    SELECT COUNT(*)                 AS n,
           SUM(x)                   AS sum_x,
           SUM(qty)                 AS sum_y,
           SUM(x*qty)               AS sum_xy,
           SUM(x*x)                 AS sum_xx
    FROM stats
), coeff AS (
    SELECT  (sum_xy - (sum_x*sum_y)/n) / (sum_xx - (sum_x*sum_x)/n)          AS slope,
            (sum_y - ((sum_xy - (sum_x*sum_y)/n) / (sum_xx - (sum_x*sum_x)/n))*sum_x)/n 
                                                                              AS intercept
    FROM agg
), pred_dates AS (        -- days needed for symmetric 5‑day windows
    SELECT '2018-12-03' AS d UNION ALL
    SELECT '2018-12-04' UNION ALL
    SELECT '2018-12-05' UNION ALL
    SELECT '2018-12-06' UNION ALL
    SELECT '2018-12-07' UNION ALL
    SELECT '2018-12-08' UNION ALL
    SELECT '2018-12-09' UNION ALL
    SELECT '2018-12-10'
), pred AS (
    SELECT  d                                           AS date_str,
            (julianday(d) - julianday('2017-01-01')) *
            coeff.slope + coeff.intercept               AS pred_qty
    FROM pred_dates
    CROSS JOIN coeff
), moving_5 AS (
    SELECT p1.date_str                        AS center_date,
           AVG(p2.pred_qty)                   AS mavg5
    FROM   pred p1
    JOIN   pred p2
      ON   ABS(julianday(p2.date_str) - julianday(p1.date_str)) <= 2
    WHERE  p1.date_str IN ('2018-12-05',
                           '2018-12-06',
                           '2018-12-07',
                           '2018-12-08')
    GROUP BY p1.date_str
)
SELECT SUM(mavg5)  AS sum_of_moving_averages
FROM   moving_5;