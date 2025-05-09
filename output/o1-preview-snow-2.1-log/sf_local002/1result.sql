WITH daily_sales AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP(o."order_purchase_timestamp", 'YYYY-MM-DD HH24:MI:SS')) AS "sale_date",
        SUM(oi."price") AS "daily_sales"
    FROM
        "E_COMMERCE"."E_COMMERCE"."ORDERS" o
        JOIN "E_COMMERCE"."E_COMMERCE"."ORDER_ITEMS" oi ON o."order_id" = oi."order_id"
    WHERE
        oi."product_id" IN (
            SELECT "product_id"
            FROM "E_COMMERCE"."E_COMMERCE"."PRODUCTS"
            WHERE "product_category_name" = 'brinquedos'
        )
        AND TO_TIMESTAMP(o."order_purchase_timestamp", 'YYYY-MM-DD HH24:MI:SS') BETWEEN '2017-01-01' AND '2018-08-29'
    GROUP BY
        DATE_TRUNC('day', TO_TIMESTAMP(o."order_purchase_timestamp", 'YYYY-MM-DD HH24:MI:SS'))
    ORDER BY
        "sale_date"
),
regression_params AS (
    SELECT
        REGR_SLOPE("daily_sales", "day_num") AS "slope",
        REGR_INTERCEPT("daily_sales", "day_num") AS "intercept"
    FROM (
        SELECT
            "sale_date",
            "daily_sales",
            DATEDIFF('day', '2016-12-31'::date, "sale_date") AS "day_num"
        FROM
            daily_sales
    )
),
predicted_sales AS (
    SELECT
        p_dates."prediction_date",
        DATEDIFF('day', '2016-12-31'::date, p_dates."prediction_date") AS "day_num",
        ROUND((params."slope" * DATEDIFF('day', '2016-12-31'::date, p_dates."prediction_date") + params."intercept"), 4) AS "predicted_daily_sales"
    FROM
        (
            SELECT DATEADD('day', ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2018-12-03'::date) AS "prediction_date"
            FROM TABLE(GENERATOR(ROWCOUNT => 8))
        ) p_dates
    CROSS JOIN regression_params params
),
moving_averages AS (
    SELECT
        "prediction_date" AS "sale_date",
        ROUND(AVG("predicted_daily_sales") OVER (
            ORDER BY "prediction_date"
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ), 4) AS "moving_average"
    FROM
        predicted_sales
)
SELECT
    ROUND(SUM("moving_average"), 4) AS "Total_Moving_Average_Sales"
FROM
    moving_averages
WHERE
    "sale_date" BETWEEN '2018-12-05' AND '2018-12-08';