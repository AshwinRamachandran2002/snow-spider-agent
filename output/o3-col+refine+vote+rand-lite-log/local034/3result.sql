WITH category_payment_counts AS (
    SELECT  p."product_category_name",
            op."payment_type",
            COUNT(*) AS num_payments
    FROM    "olist_order_payments" op
    JOIN    "olist_order_items"    oi ON op."order_id" = oi."order_id"
    JOIN    "olist_products"       p  ON oi."product_id" = p."product_id"
    GROUP BY p."product_category_name",
             op."payment_type"
),
preferred_method AS (
    SELECT  "product_category_name",
            MAX(num_payments) AS max_payments
    FROM    category_payment_counts
    GROUP BY "product_category_name"
)
SELECT  AVG(cpc.num_payments) AS avg_total_payments_preferred_method
FROM    category_payment_counts cpc
JOIN    preferred_method pm
       ON  cpc."product_category_name" = pm."product_category_name"
      AND cpc.num_payments             = pm.max_payments;