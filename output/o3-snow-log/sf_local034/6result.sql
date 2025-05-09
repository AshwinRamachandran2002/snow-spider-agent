WITH category_payment_counts AS (
    /* count how many individual payment records each payment_type has in every product category */
    SELECT
        prod."product_category_name",
        pay."payment_type",
        COUNT(*)                                                   AS "num_payments"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS"         pay
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"            items
         ON pay."order_id" = items."order_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS"               prod
         ON items."product_id" = prod."product_id"
    WHERE prod."product_category_name" IS NOT NULL
    GROUP BY prod."product_category_name", pay."payment_type"
),

preferred_method_per_category AS (
    /* pick the payment_type with the highest number of payments in each category */
    SELECT
        "product_category_name",
        "payment_type",
        "num_payments"
    FROM (
        SELECT
            "product_category_name",
            "payment_type",
            "num_payments",
            ROW_NUMBER() OVER (PARTITION BY "product_category_name"
                               ORDER BY "num_payments" DESC)     AS rn
        FROM category_payment_counts
    )
    WHERE rn = 1
)

SELECT
    ROUND(AVG("num_payments"), 4) AS "average_num_payments_most_preferred_method"
FROM preferred_method_per_category;