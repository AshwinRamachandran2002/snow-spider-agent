WITH payment_counts AS (
    SELECT
        p."product_category_name",
        pay."payment_type",
        COUNT(*) AS "payment_count"
    FROM
        "olist_order_payments" AS pay
    JOIN
        "olist_order_items" AS oi ON pay."order_id" = oi."order_id"
    JOIN
        "olist_products" AS p ON oi."product_id" = p."product_id"
    GROUP BY
        p."product_category_name",
        pay."payment_type"
),
ranked_payments AS (
    SELECT
        pc."product_category_name",
        pc."payment_type",
        pc."payment_count",
        ROW_NUMBER() OVER (
            PARTITION BY pc."product_category_name"
            ORDER BY pc."payment_count" DESC
        ) AS rn
    FROM
        payment_counts pc
)
SELECT
    AVG(rp."payment_count") AS "average_payment_count"
FROM
    ranked_payments rp
WHERE
    rp.rn = 1;