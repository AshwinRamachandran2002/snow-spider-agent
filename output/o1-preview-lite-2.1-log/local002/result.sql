WITH daily_sales AS (
    SELECT DATE(o."order_purchase_timestamp") AS "Order_Date",
           julianday(DATE(o."order_purchase_timestamp")) - julianday('2017-01-01') AS x,
           COUNT(*) AS y
    FROM "orders" o
    INNER JOIN "order_items" oi ON o."order_id" = oi."order_id"
    INNER JOIN "products" p ON oi."product_id" = p."product_id"
    INNER JOIN "product_category_name_translation" t
        ON p."product_category_name" = t."product_category_name"
    WHERE t."product_category_name_english" = 'toys'
      AND DATE(o."order_purchase_timestamp") BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP BY "Order_Date"
),
regression_data AS (
    SELECT
        COUNT(*) AS n,
        SUM(x) AS sum_x,
        SUM(y) AS sum_y,
        SUM(x * x) AS sum_xx,
        SUM(x * y) AS sum_xy
    FROM daily_sales
),
regression_params AS (
    SELECT
        (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x) AS slope,
        (sum_y - ((n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)) * sum_x) / n AS intercept
    FROM regression_data
),
date_range AS (
    SELECT DATE('2017-01-01') AS "Order_Date"
    UNION ALL
    SELECT DATE(DATE("Order_Date", '+1 day'))
    FROM date_range
    WHERE DATE("Order_Date") < DATE('2018-12-10')
),
predicted_sales AS (
    SELECT
        dr."Order_Date",
        rp.intercept + rp.slope * (julianday(dr."Order_Date") - julianday('2017-01-01')) AS y_predicted
    FROM date_range dr
    CROSS JOIN regression_params rp
),
moving_average AS (
    SELECT
        ps1."Order_Date",
        AVG(ps2.y_predicted) AS moving_average
    FROM predicted_sales ps1
    INNER JOIN predicted_sales ps2 ON ps2."Order_Date" BETWEEN DATE(ps1."Order_Date", '-2 day') AND DATE(ps1."Order_Date", '+2 day')
    GROUP BY ps1."Order_Date"
)
SELECT
    SUM(ma.moving_average) AS Total_Moving_Average
FROM moving_average ma
WHERE ma."Order_Date" BETWEEN '2018-12-05' AND '2018-12-08';