WITH toy_sales AS (      -- daily toy-units between 2017-01-01 and 2018-08-29
    SELECT DATE(o."order_purchase_timestamp")                     AS sale_date,
           COUNT(*)                                               AS units_sold
    FROM   "orders"        AS o
    JOIN   "order_items"   AS oi USING("order_id")
    JOIN   "products"      AS p  ON p."product_id" = oi."product_id"
    JOIN   "product_category_name_translation" AS t
           ON p."product_category_name" = t."product_category_name"
    WHERE  LOWER(t."product_category_name_english") LIKE '%toy%'
      AND  DATE(o."order_purchase_timestamp") BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP  BY sale_date
),
stats AS (                -- regression building blocks
    SELECT COUNT(*)                           AS n,
           SUM(x)                             AS sum_x,
           SUM(y)                             AS sum_y,
           SUM(x*y)                           AS sum_xy,
           SUM(x*x)                           AS sum_x2
    FROM  (
        SELECT (JULIANDAY(sale_date)-JULIANDAY('2017-01-01')) AS x,
               units_sold                                     AS y
        FROM   toy_sales
    )
),
coeff AS (                -- slope & intercept
    SELECT (1.0*n*sum_xy - sum_x*sum_y) /
           (1.0*n*sum_x2 - sum_x*sum_x)                       AS slope,
           (sum_y - ((1.0*n*sum_xy - sum_x*sum_y) /
                     (1.0*n*sum_x2 - sum_x*sum_x))*sum_x) /
           (1.0*n)                                            AS intercept
    FROM   stats
),
future_dates AS (         -- 2018-12-03 … 2018-12-10
    SELECT '2018-12-03' AS d UNION ALL SELECT '2018-12-04'
    UNION ALL SELECT '2018-12-05' UNION ALL SELECT '2018-12-06'
    UNION ALL SELECT '2018-12-07' UNION ALL SELECT '2018-12-08'
    UNION ALL SELECT '2018-12-09' UNION ALL SELECT '2018-12-10'
),
preds AS (                -- predictions for each future date
    SELECT fd.d,
           ((JULIANDAY(fd.d) - JULIANDAY('2017-01-01'))*coeff.slope
            + coeff.intercept)                                AS yhat
    FROM   future_dates AS fd, coeff
),
ma5 AS (                   -- 5-day symmetric moving-averages (centre days 5-8 Dec)
    SELECT p1.d                                              AS centre_day,
           (SELECT AVG(p2.yhat)
              FROM preds p2
              WHERE p2.d BETWEEN DATE(p1.d,'-2 day')
                           AND DATE(p1.d,'+2 day'))          AS ma_val
    FROM   preds AS p1
    WHERE  p1.d BETWEEN '2018-12-05' AND '2018-12-08'
)
SELECT ROUND(SUM(ma_val),4) AS sum_of_4_moving_averages
FROM   ma5;