WITH RECURSIVE
    -- 1. calendar of every day in the training window
    dates(dt) AS (
        SELECT DATE('2017-01-01')
        UNION ALL
        SELECT DATE(dt,'+1 day') FROM dates WHERE dt < '2018-08-29'
    ),

    -- 2. daily quantity of TOY items sold (0 when no sale that day)
    daily_sales AS (
        SELECT
            d.dt,
            COALESCE( SUM(
                CASE
                    -- english name that contains the word "toy"
                    WHEN LOWER(pct.product_category_name_english) LIKE '%toy%' THEN 1
                    ELSE 0
                END
            ), 0 ) AS qty
        FROM dates            AS d
        LEFT JOIN orders      AS o   ON DATE(o.order_purchase_timestamp) = d.dt
        LEFT JOIN order_items AS oi  ON oi.order_id = o.order_id
        LEFT JOIN products    AS p   ON p.product_id = oi.product_id
        LEFT JOIN product_category_name_translation AS pct
                                      ON pct.product_category_name = p.product_category_name
        GROUP BY d.dt
    ),

    -- 3. compute simple‑linear‑regression coefficients over the training set
    stats AS (
        SELECT
            COUNT(*)                                                     AS n,
            SUM((julianday(dt)-julianday('2017-01-01')) * qty)           AS sum_xy,
            SUM(julianday(dt)-julianday('2017-01-01'))                   AS sum_x,
            SUM(qty)                                                     AS sum_y,
            SUM( (julianday(dt)-julianday('2017-01-01'))*
                 (julianday(dt)-julianday('2017-01-01')) )               AS sum_x2
        FROM daily_sales
    ),
    coeff AS (
        SELECT
            (n*sum_xy - sum_x*sum_y) * 1.0 / (n*sum_x2 - sum_x*sum_x)    AS slope,
            (sum_y - ( (n*sum_xy - sum_x*sum_y) * 1.0 /
                       (n*sum_x2 - sum_x*sum_x) ) * sum_x) * 1.0 / n     AS intercept
        FROM stats
    ),

    -- 4. calendar for the prediction window (Dec‑03‑2018 .. Dec‑10‑2018)
    future_dates(fd) AS (
        SELECT DATE('2018-12-03')
        UNION ALL
        SELECT DATE(fd,'+1 day') FROM future_dates WHERE fd < '2018-12-10'
    ),

    -- 5. regression prediction for every date in that window
    predictions AS (
        SELECT
            fd,
            c.slope * (julianday(fd) - julianday('2017-01-01')) + c.intercept AS pred
        FROM future_dates
        CROSS JOIN coeff AS c
    ),

    -- 6. 5‑day symmetric moving average for 5‑Dec .. 8‑Dec‑2018
    ma5 AS (
        SELECT
            p1.fd                                             AS target_day,
            (SELECT AVG(p2.pred)
               FROM predictions p2
              WHERE p2.fd BETWEEN DATE(p1.fd,'-2 day') AND DATE(p1.fd,'+2 day')
            )                                                 AS ma5
        FROM predictions p1
        WHERE p1.fd BETWEEN '2018-12-05' AND '2018-12-08'
    )

-- 7. final answer: sum of the four 5‑day moving averages
SELECT SUM(ma5) AS sum_of_5day_moving_averages
FROM   ma5;