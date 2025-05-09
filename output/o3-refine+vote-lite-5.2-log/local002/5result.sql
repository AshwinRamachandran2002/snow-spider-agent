WITH toy_categories AS (
    SELECT product_category_name
    FROM product_category_name_translation
    WHERE LOWER(product_category_name_english) = 'toys'
), 
daily_sales AS (
    SELECT DATE(o.order_purchase_timestamp)           AS sale_date,
           COUNT(*)                                   AS qty
    FROM   orders            AS o
    JOIN   order_items       AS oi ON oi.order_id = o.order_id
    JOIN   products          AS p  ON p.product_id   = oi.product_id
    JOIN   toy_categories    AS tc ON tc.product_category_name = p.product_category_name
    WHERE  DATE(o.order_purchase_timestamp) BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP  BY sale_date
), 
reg AS (        /* prepare sums for simple linear regression y = a + b*x */
    SELECT COUNT(*)                                                  AS n,
           SUM(julianday(sale_date) - julianday('2017-01-01'))       AS sum_x,
           SUM(qty)                                                  AS sum_y,
           SUM((julianday(sale_date) - julianday('2017-01-01'))*qty) AS sum_xy,
           SUM((julianday(sale_date) - julianday('2017-01-01'))*
               (julianday(sale_date) - julianday('2017-01-01')))      AS sum_xx
    FROM   daily_sales
),
coeff AS (      /* slope and intercept */
    SELECT (n*sum_xy - sum_x*sum_y) / (n*sum_xx - sum_x*sum_x)               AS slope,
           (sum_y - ((n*sum_xy - sum_x*sum_y) / (n*sum_xx - sum_x*sum_x))*sum_x) / n
                                                                              AS intercept
    FROM   reg
), 
pred_dates AS ( /* dates for which prediction is needed: 2018‑12‑03 … 2018‑12‑10 */
    SELECT DATE('2018-12-03', '+'||v.d||' day') AS pred_date
    FROM (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
          UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7) v
), 
predictions AS (/* predicted toy sales for each date using the regression line */
    SELECT pd.pred_date,
           c.intercept + c.slope * (julianday(pd.pred_date) - julianday('2017-01-01'))
               AS predicted_sales
    FROM   pred_dates pd
    CROSS  JOIN coeff c
), 
moving_avg AS ( /* 5‑day symmetric moving average centred on 2018‑12‑05 … 2018‑12‑08 */
    SELECT centre.pred_date AS centre_date,
           (SELECT AVG(p2.predicted_sales)
            FROM   predictions p2
            WHERE  p2.pred_date BETWEEN DATE(centre.pred_date,'-2 day')
                                   AND     DATE(centre.pred_date,'+2 day')
           ) AS ma5
    FROM   predictions AS centre
    WHERE  centre.pred_date BETWEEN '2018-12-05' AND '2018-12-08'
)
SELECT SUM(ma5) AS sum_of_5day_moving_averages
FROM   moving_avg;