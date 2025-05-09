WITH
    category_payment_counts AS (
        SELECT
            pt.product_category_name_english AS category,
            oop.payment_type,
            COUNT(*) AS payment_count
        FROM
            olist_order_items AS ooi
            JOIN olist_products AS p ON ooi.product_id = p.product_id
            JOIN product_category_name_translation AS pt ON p.product_category_name = pt.product_category_name
            JOIN olist_order_payments AS oop ON ooi.order_id = oop.order_id
        GROUP BY
            pt.product_category_name_english,
            oop.payment_type
    ),
    most_preferred_payment_methods AS (
        SELECT
            category,
            payment_type
        FROM (
            SELECT
                category,
                payment_type,
                payment_count,
                RANK() OVER (PARTITION BY category ORDER BY payment_count DESC) AS rk
            FROM category_payment_counts
        )
        WHERE rk = 1
    ),
    order_payment_counts AS (
        SELECT
            order_id,
            COUNT(*) AS total_payment_count
        FROM
            olist_order_payments
        GROUP BY
            order_id
    ),
    order_categories AS (
        SELECT DISTINCT
            ooi.order_id,
            pt.product_category_name_english AS category,
            oop.payment_type
        FROM
            olist_order_items AS ooi
            JOIN olist_products AS p ON ooi.product_id = p.product_id
            JOIN product_category_name_translation AS pt ON p.product_category_name = pt.product_category_name
            JOIN olist_order_payments AS oop ON ooi.order_id = oop.order_id
    ),
    orders_with_preferred_payment_method AS (
        SELECT
            oc.order_id,
            oc.category
        FROM
            order_categories AS oc
            JOIN most_preferred_payment_methods AS mppm ON
                oc.category = mppm.category AND
                oc.payment_type = mppm.payment_type
    ),
    category_order_payments AS (
        SELECT
            owppm.category,
            owppm.order_id,
            opc.total_payment_count
        FROM
            orders_with_preferred_payment_method AS owppm
            JOIN order_payment_counts AS opc ON owppm.order_id = opc.order_id
    )
SELECT
    category,
    ROUND(AVG(total_payment_count), 4) AS average_total_payment_count
FROM
    category_order_payments
GROUP BY
    category
ORDER BY
    average_total_payment_count DESC;