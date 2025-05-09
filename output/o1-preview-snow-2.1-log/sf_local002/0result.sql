WITH daily_sales AS (
    SELECT
        DATE(o."order_purchase_timestamp") AS "sale_date",
        SUM(oi."price") AS "total_sales"
    FROM
        "E_COMMERCE"."E_COMMERCE"."ORDER_ITEMS" AS oi
        JOIN "E_COMMERCE"."E_COMMERCE"."ORDERS" AS o
            ON oi."order_id" = o."order_id"
        JOIN "E_COMMERCE"."E_COMMERCE"."PRODUCTS" AS p
            ON oi."product_id" = p."product_id"
        JOIN "E_COMMERCE"."E_COMMERCE"."PRODUCT_CATEGORY_NAME_TRANSLATION" AS t
            ON p."product_category_name" = t."product_category_name"
    WHERE
        t."product_category_name_english" = 'toys'
        AND o."order_purchase_timestamp" BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP BY
        DATE(o."order_purchase_timestamp")
),
sales_with_daynum AS (
    SELECT
        "sale_date",
        "total_sales",
        DATEDIFF('day', '2017-01-01', "sale_date") AS "day_num"
    FROM daily_sales
),
regression_coef AS (
    SELECT
        REGR_SLOPE("total_sales", "day_num") AS "slope",
        REGR_INTERCEPT("total_sales", "day_num") AS "intercept"
    FROM sales_with_daynum
),
predicted_sales AS (
    SELECT
        DATEADD('day', "day_offset", '2018-12-03') AS "sale_date",
        ("intercept" + "slope" * DATEDIFF('day', '2017-01-01', DATEADD('day', "day_offset", '2018-12-03'))) AS "predicted_sales"
    FROM regression_coef,
    (
        SELECT 0 AS "day_offset" UNION ALL
        SELECT 1 AS "day_offset" UNION ALL
        SELECT 2 AS "day_offset" UNION ALL
        SELECT 3 AS "day_offset" UNION ALL
        SELECT 4 AS "day_offset" UNION ALL
        SELECT 5 AS "day_offset" UNION ALL
        SELECT 6 AS "day_offset" UNION ALL
        SELECT 7 AS "day_offset"
    )
),
moving_average AS (
    SELECT
        "sale_date",
        ROUND(AVG("predicted_sales") OVER (
            ORDER BY "sale_date"
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ), 4) AS "moving_avg"
    FROM predicted_sales
),
total_moving_average AS (
    SELECT
        ROUND(SUM("moving_avg"), 4) AS "Total_Moving_Average_Sales"
    FROM moving_average
    WHERE "sale_date" BETWEEN '2018-12-05' AND '2018-12-08'
)
SELECT
    "Total_Moving_Average_Sales"
FROM total_moving_average;