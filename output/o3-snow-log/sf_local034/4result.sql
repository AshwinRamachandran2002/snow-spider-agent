/* 1)  Count how many payment records each payment method has inside every
       product category.
   2)  For every category keep the payment method with the highest count
       (the “most-preferred” one).
   3)  Take the average of those counts across all categories.             */

WITH category_payment_counts AS (
    SELECT
        pr."product_category_name",
        p."payment_type",
        COUNT(*)                           AS "num_payments"
    FROM  BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS   p
    JOIN  BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_ITEMS      oi
          ON p."order_id" = oi."order_id"
    JOIN  BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_PRODUCTS         pr
          ON oi."product_id" = pr."product_id"
    WHERE pr."product_category_name" IS NOT NULL
    GROUP BY
        pr."product_category_name",
        p."payment_type"
),

preferred_method_per_category AS (
    SELECT
        "product_category_name",
        "payment_type",
        "num_payments"
    FROM (
        SELECT
            cpc.*,
            ROW_NUMBER() OVER (
                PARTITION BY "product_category_name"
                ORDER BY "num_payments" DESC NULLS LAST
            ) AS rn
        FROM category_payment_counts cpc
    )
    WHERE rn = 1          -- keep only the most preferred payment method
)

SELECT
    AVG("num_payments") AS "avg_num_payments_for_preferred_method"
FROM preferred_method_per_category;