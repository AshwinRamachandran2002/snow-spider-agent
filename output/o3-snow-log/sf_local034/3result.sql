WITH payments_per_category AS (
    SELECT
        PR."product_category_name"                                AS category,
        OP."payment_type",
        COUNT(*)                                                  AS payment_cnt
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS      OI
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_PRODUCTS         PR
         ON OI."product_id" = PR."product_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS   OP
         ON OI."order_id"  = OP."order_id"
    WHERE PR."product_category_name" IS NOT NULL
    GROUP BY
        PR."product_category_name",
        OP."payment_type"
),
preferred_payment AS (
    SELECT
        category,
        payment_cnt,
        ROW_NUMBER() OVER (PARTITION BY category
                           ORDER BY payment_cnt DESC, OP."payment_type") AS rn
    FROM payments_per_category OP
)
SELECT
    AVG(payment_cnt) AS average_payments_of_preferred_method
FROM preferred_payment
WHERE rn = 1;