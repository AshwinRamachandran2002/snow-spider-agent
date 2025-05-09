WITH ranked_payments AS (
    SELECT
        p."product_category_name",
        pay."payment_type",
        COUNT(*)                         AS payment_cnt,
        ROW_NUMBER() OVER (
            PARTITION BY p."product_category_name"
            ORDER BY COUNT(*) DESC
        )                                AS rn
    FROM   "olist_order_payments" AS pay
    JOIN   "olist_order_items"    AS oi  ON pay."order_id" = oi."order_id"
    JOIN   "olist_products"       AS p   ON oi."product_id" = p."product_id"
    GROUP  BY p."product_category_name",
             pay."payment_type"
)
SELECT
    "product_category_name",
    "payment_type",
    payment_cnt
FROM   ranked_payments
WHERE  rn = 1                -- keep the most-common payment type per category
ORDER  BY payment_cnt DESC   -- rank categories by that count
LIMIT  3;                    -- top three categories