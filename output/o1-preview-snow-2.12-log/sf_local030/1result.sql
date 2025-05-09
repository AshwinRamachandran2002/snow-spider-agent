WITH city_totals AS (
    SELECT
        c."customer_city",
        SUM(p."payment_value") AS "total_payments",
        COUNT(DISTINCT o."order_id") AS "total_delivered_order_counts"
    FROM
        "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" c
        JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o
            ON c."customer_id" = o."customer_id"
        JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" p
            ON o."order_id" = p."order_id"
    WHERE
        o."order_status" = 'delivered'
    GROUP BY
        c."customer_city"
    ORDER BY
        "total_payments" ASC
    LIMIT 5
)
SELECT
    ROUND(AVG("total_payments"), 4) AS "average_total_payments",
    ROUND(AVG("total_delivered_order_counts"), 4) AS "average_total_order_counts"
FROM
    city_totals;