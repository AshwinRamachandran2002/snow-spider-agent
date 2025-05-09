WITH RECURSIVE
    -- calendar from 2017-01-01 through 2018-12-10 (enough to build the 5-day windows)
    dates(d) AS (
        SELECT DATE('2017-01-01')
        UNION ALL
        SELECT DATE(d,'+1 day') FROM dates WHERE d < '2018-12-10'
    ),

    -- daily toy–item counts observed in the historical window
    toy_sales AS (
        SELECT SUBSTR(o."order_purchase_timestamp",1,10) AS sale_date,
               COUNT(*)                                 AS items
        FROM   "orders"      o
        JOIN   "order_items" oi ON oi."order_id" = o."order_id"
        JOIN   "products"    p  ON p."product_id" = oi."product_id"
        JOIN   "product_category_name_translation" t
               ON p."product_category_name" = t."product_category_name"
        WHERE  t."product_category_name_english" LIKE '%toy%'
        GROUP  BY sale_date
    ),

    -- put the counts on the full calendar, fill gaps with zero,
    -- and create a numerical “day index” (x)
    calendar AS (
        SELECT d                                               AS date,
               COALESCE(items,0)                               AS y,
               CAST(julianday(d) - julianday('2017-01-01') AS REAL) AS x
        FROM   dates
        LEFT   JOIN toy_sales ON d = sale_date
    ),

    -- training set: 2017-01-01 .. 2018-08-29
    train AS (
        SELECT * FROM calendar
        WHERE  date BETWEEN '2017-01-01' AND '2018-08-29'
    ),

    -- regression aggregates
    stats AS (
        SELECT COUNT(*)      AS n,
               SUM(x)        AS sumx,
               SUM(y)        AS sumy,
               SUM(x*y)      AS sumxy,
               SUM(x*x)      AS sumx2
        FROM   train
    ),

    -- slope & intercept of simple linear regression  y = a + b·x
    coeff AS (
        SELECT (n*sumxy - sumx*sumy)        / (n*sumx2 - sumx*sumx)  AS slope,
               (sumy - ((n*sumxy - sumx*sumy) /
                        (n*sumx2 - sumx*sumx))*sumx) / n            AS intercept
        FROM   stats
    ),

    -- daily predictions for the whole calendar
    pred AS (
        SELECT c.date,
               (coeff.intercept + coeff.slope * c.x) AS y_pred
        FROM   calendar c, coeff
    ),

    -- 5-day symmetric moving average for 5-8 Dec 2018
    ma5 AS (
        SELECT p.date,
               (SELECT AVG(y_pred)
                FROM   pred q
                WHERE  q.date BETWEEN DATE(p.date,'-2 day')
                                 AND     DATE(p.date,'+2 day')) AS ma5
        FROM   pred p
        WHERE  p.date BETWEEN '2018-12-05' AND '2018-12-08'
    )

-- required result: sum of the four moving averages
SELECT SUM(ma5) AS sum_of_moving_averages
FROM   ma5;