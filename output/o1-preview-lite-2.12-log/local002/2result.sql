WITH sales_data AS (
        SELECT 
            DATE("orders"."order_purchase_timestamp") AS "order_date",
            SUM("order_items"."price") AS "daily_sales"
        FROM "orders"
        JOIN "order_items" ON "orders"."order_id" = "order_items"."order_id"
        WHERE "order_items"."product_id" IN (
                SELECT "product_id"
                FROM "products"
                WHERE "product_category_name" IN (
                    SELECT "product_category_name"
                    FROM "product_category_name_translation"
                    WHERE "product_category_name_english" = 'toys'
                )
            )
            AND DATE("orders"."order_purchase_timestamp") BETWEEN '2017-01-01' AND '2018-08-29'
        GROUP BY "order_date"
    ),
    sales_with_x AS (
        SELECT 
            "order_date",
            CAST(JULIANDAY("order_date") - JULIANDAY('2017-01-01') AS REAL) AS x_i,
            "daily_sales" AS y_i
        FROM sales_data
    ),
    sums AS (
        SELECT
            COUNT(*) AS N,
            SUM(x_i) AS Sum_x,
            SUM(y_i) AS Sum_y,
            SUM(x_i * x_i) AS Sum_xx,
            SUM(x_i * y_i) AS Sum_xy
        FROM sales_with_x
    ),
    coefficients AS (
        SELECT
            N,
            Sum_x,
            Sum_y,
            Sum_xx,
            Sum_xy,
            (N * Sum_xy - Sum_x * Sum_y) / (N * Sum_xx - Sum_x * Sum_x) AS b,
            (Sum_y - ((N * Sum_xy - Sum_x * Sum_y) / (N * Sum_xx - Sum_x * Sum_x)) * Sum_x) / N AS a
        FROM sums
    ),
    predicted_sales AS (
        SELECT 
            DATE('2018-12-03', '+' || n || ' days') AS "order_date",
            CAST(JULIANDAY(DATE('2018-12-03', '+' || n || ' days')) - JULIANDAY('2017-01-01') AS REAL) AS x_i,
            (SELECT a FROM coefficients) + (SELECT b FROM coefficients) * CAST(JULIANDAY(DATE('2018-12-03', '+' || n || ' days')) - JULIANDAY('2017-01-01') AS REAL) AS y_i_predicted
        FROM (
            SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
        ) AS numbers
    ),
    moving_averages AS (
        SELECT
            ps."order_date",
            (SELECT AVG(ps2.y_i_predicted)
             FROM predicted_sales AS ps2
             WHERE ps2."order_date" BETWEEN DATE(ps."order_date", '-2 days') AND DATE(ps."order_date", '+2 days')
            ) AS "moving_average"
        FROM predicted_sales AS ps
        WHERE ps."order_date" BETWEEN '2018-12-05' AND '2018-12-08'
    )
    SELECT ROUND(SUM("moving_average"), 4) AS "Sum_of_5-day_Symmetric_Moving_Averages"
    FROM moving_averages;