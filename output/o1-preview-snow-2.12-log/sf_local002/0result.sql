WITH daily_sales AS (
    SELECT 
        TO_DATE(SUBSTR(o."order_purchase_timestamp", 1, 10)) AS "date",
        SUM(oi."price") AS "daily_sales"
    FROM 
        "E_COMMERCE"."E_COMMERCE"."ORDERS" o
    JOIN
        "E_COMMERCE"."E_COMMERCE"."ORDER_ITEMS" oi
            ON o."order_id" = oi."order_id"
    JOIN
        "E_COMMERCE"."E_COMMERCE"."PRODUCTS" p
            ON oi."product_id" = p."product_id"
    WHERE
        o."order_purchase_timestamp" >= '2017-01-01'
        AND o."order_purchase_timestamp" <= '2018-08-29'
        AND p."product_category_name" = 'brinquedos'
    GROUP BY
        "date"
),
regression_params AS (
    SELECT
        REGR_SLOPE("daily_sales", "days_since_start") AS "slope",
        REGR_INTERCEPT("daily_sales", "days_since_start") AS "intercept"
    FROM (
        SELECT
            "date",
            "daily_sales",
            DATEDIFF('day', TO_DATE('2017-01-01'), "date") AS "days_since_start"
        FROM
            daily_sales
    )
),
future_dates AS (
    SELECT TO_DATE('2018-12-03') AS "date" UNION ALL
    SELECT TO_DATE('2018-12-04') UNION ALL
    SELECT TO_DATE('2018-12-05') UNION ALL
    SELECT TO_DATE('2018-12-06') UNION ALL
    SELECT TO_DATE('2018-12-07') UNION ALL
    SELECT TO_DATE('2018-12-08') UNION ALL
    SELECT TO_DATE('2018-12-09') UNION ALL
    SELECT TO_DATE('2018-12-10')
),
predicted_sales AS (
    SELECT
        f."date",
        r."intercept" + r."slope" * DATEDIFF('day', TO_DATE('2017-01-01'), f."date") AS "predicted_sales"
    FROM
        future_dates f
    CROSS JOIN
        regression_params r
),
moving_average AS (
    SELECT
        p1."date",
        ROUND(AVG(p2."predicted_sales"), 4) AS "5-Day Symmetric Moving Average"
    FROM
        predicted_sales p1
    JOIN
        predicted_sales p2
            ON ABS(DATEDIFF('day', p1."date", p2."date")) <= 2
    WHERE
        p1."date" BETWEEN '2018-12-05' AND '2018-12-08'
    GROUP BY
        p1."date"
    ORDER BY
        p1."date"
)
SELECT
    TO_VARCHAR("date", 'YYYY-MM-DD') AS "Date",
    "5-Day Symmetric Moving Average"
FROM
    moving_average
UNION ALL
SELECT
    'Total Sum' AS "Date",
    ROUND(SUM("5-Day Symmetric Moving Average"), 4) AS "5-Day Symmetric Moving Average"
FROM
    moving_average;