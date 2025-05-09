WITH
-- 1. all toy items with their purchase date
toys AS (
    SELECT 
        DATE(o.order_purchase_timestamp)               AS order_date,
        oi.order_id
    FROM "order_items"               AS oi
    JOIN "orders"                    AS o  ON o.order_id  = oi.order_id
    JOIN "products"                  AS p  ON p.product_id = oi.product_id
    JOIN "product_category_name_translation" AS t
                              ON t.product_category_name = p.product_category_name
    WHERE t.product_category_name_english = 'toys'
),

-- 2. daily toy‑item quantities (one row per date)
daily AS (
    SELECT
        order_date,
        COUNT(*)                      AS qty
    FROM toys
    WHERE order_date BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP BY order_date
),

-- 3. regression statistics
stats AS (
    SELECT
        COUNT(*)                                                            AS n,
        SUM( (julianday(order_date)-julianday('2017-01-01')) * qty )        AS sum_xy,
        SUM(  julianday(order_date)-julianday('2017-01-01') )               AS sum_x,
        SUM( (julianday(order_date)-julianday('2017-01-01')) *
             (julianday(order_date)-julianday('2017-01-01')) )              AS sum_x2,
        SUM(qty)                                                            AS sum_y
    FROM daily
),

-- 4. slope and intercept of the simple linear regression
coeff AS (
    SELECT
        (n*sum_xy - sum_x*sum_y) / (n*sum_x2 - sum_x*sum_x)                AS slope,
        (sum_y - ((n*sum_xy - sum_x*sum_y) / (n*sum_x2 - sum_x*sum_x))*sum_x)/n
                                                                            AS intercept
    FROM stats
),

-- 5. dates we need predictions for (Dec‑03‑2018 … Dec‑10‑2018)
future_dates AS (
    SELECT '2018-12-03' AS pred_date UNION ALL
    SELECT '2018-12-04' UNION ALL
    SELECT '2018-12-05' UNION ALL
    SELECT '2018-12-06' UNION ALL
    SELECT '2018-12-07' UNION ALL
    SELECT '2018-12-08' UNION ALL
    SELECT '2018-12-09' UNION ALL
    SELECT '2018-12-10'
),

-- 6. predicted toy sales for those dates
predictions AS (
    SELECT
        pred_date,
        (SELECT intercept + slope * (julianday(pred_date) - julianday('2017-01-01'))
         FROM coeff)                                                       AS predicted_qty
    FROM future_dates
),

-- 7. 5‑day symmetric moving averages for Dec‑05 … Dec‑08
moving_avg AS (
    SELECT
        p1.pred_date,
        (SELECT AVG(p2.predicted_qty)
         FROM predictions p2
         WHERE p2.pred_date BETWEEN DATE(p1.pred_date,'-2 day')
                               AND     DATE(p1.pred_date,'+2 day') )       AS ma5
    FROM predictions p1
    WHERE p1.pred_date BETWEEN '2018-12-05' AND '2018-12-08'
)

-- 8. final answer: sum of the four 5‑day moving averages
SELECT SUM(ma5) AS sum_of_5day_moving_avgs
FROM   moving_avg;