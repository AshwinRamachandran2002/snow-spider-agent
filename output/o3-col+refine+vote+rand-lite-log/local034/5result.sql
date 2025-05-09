WITH payment_counts AS (
    SELECT
        p."product_category_name",
        op."payment_type",
        COUNT(DISTINCT op."order_id" || '-' || op."payment_sequential") AS payments_cnt
    FROM "olist_order_payments"   AS op
    JOIN "olist_order_items"      AS oi ON oi."order_id" = op."order_id"
    JOIN "olist_products"         AS p  ON p."product_id"  = oi."product_id"
    GROUP BY
        p."product_category_name",
        op."payment_type"
),
ranked AS (
    SELECT
        pc.*,
        RANK() OVER (PARTITION BY pc."product_category_name"
                     ORDER BY pc.payments_cnt DESC) AS rk
    FROM payment_counts pc
),
preferred_method_totals AS (
    SELECT
        "product_category_name",
        SUM(payments_cnt) AS total_pref_method_payments   -- sums when there is a tie
    FROM ranked
    WHERE rk = 1
    GROUP BY "product_category_name"
)
SELECT
    AVG(total_pref_method_payments) AS avg_payments_for_pref_method
FROM preferred_method_totals;