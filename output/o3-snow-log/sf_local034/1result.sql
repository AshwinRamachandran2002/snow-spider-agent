WITH category_payment_counts AS (        -- payments associated to each product category
    SELECT 
        prod."product_category_name"                AS category ,
        pay."payment_type"                          AS payment_type ,
        COUNT(*)                                    AS payment_count          -- number of payment rows
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS"   pay
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS"      oi
          ON pay."order_id" = oi."order_id"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_PRODUCTS"         prod
          ON oi."product_id" = prod."product_id"
    WHERE prod."product_category_name" IS NOT NULL
    GROUP BY 
        prod."product_category_name",
        pay."payment_type"
),
preferred_payment_per_category AS (      -- pick the most-used payment method in each category
    SELECT 
        category,
        payment_type,
        payment_count
    FROM (
        SELECT 
            category,
            payment_type,
            payment_count,
            ROW_NUMBER() OVER (PARTITION BY category 
                               ORDER BY payment_count DESC, payment_type) AS rn
        FROM category_payment_counts
    )
    WHERE rn = 1                         -- keep only the top (most preferred) payment method
)
SELECT 
    ROUND(AVG(payment_count),4) AS "AVG_TOTAL_PAYMENTS_FOR_PREFERRED_METHOD"
FROM preferred_payment_per_category;