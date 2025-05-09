WITH base AS (
    SELECT
        pr."product_category_name",
        pay."payment_type"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS      oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_PRODUCTS          pr
          ON oi."product_id" = pr."product_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS    pay
          ON oi."order_id" = pay."order_id"
),
category_payment_counts AS (
    SELECT
        "product_category_name",
        "payment_type",
        COUNT(*) AS payment_cnt
    FROM base
    GROUP BY
        "product_category_name",
        "payment_type"
),
most_preferred AS (
    SELECT
        "product_category_name",
        "payment_type",
        payment_cnt,
        ROW_NUMBER() OVER (PARTITION BY "product_category_name"
                           ORDER BY payment_cnt DESC, "payment_type") AS rn
    FROM category_payment_counts
)
SELECT
    AVG(payment_cnt) AS avg_most_preferred_payment_cnt
FROM most_preferred
WHERE rn = 1;