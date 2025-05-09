WITH
item_stats AS (
    SELECT
        oi.seller_id,
        COUNT(*)                                 AS total_units_sold,
        SUM(oi.price)                            AS total_sales,
        AVG(oi.price)                            AS average_item_price
    FROM order_items AS oi
    GROUP BY oi.seller_id
),
review_stats AS (
    SELECT
        x.seller_id,
        AVG(x.review_score)                     AS average_review_score
    FROM (
        SELECT DISTINCT
               oi.seller_id,
               oi.order_id,
               r.review_score
        FROM order_items  AS oi
        JOIN order_reviews AS r
          ON r.order_id = oi.order_id
        WHERE r.review_score IS NOT NULL
    ) AS x
    GROUP BY x.seller_id
),
packing_stats AS (
    SELECT
        x.seller_id,
        AVG(x.packing_time_days)                AS average_packing_time_days
    FROM (
        SELECT DISTINCT
               oi.seller_id,
               o.order_id,
               julianday(o.order_delivered_carrier_date)
               - julianday(o.order_approved_at) AS packing_time_days
        FROM order_items AS oi
        JOIN orders      AS o ON o.order_id = oi.order_id
        WHERE o.order_delivered_carrier_date IS NOT NULL
          AND o.order_approved_at            IS NOT NULL
    ) AS x
    GROUP BY x.seller_id
),
category_rank AS (
    SELECT
        oi.seller_id,
        COALESCE(t.product_category_name_english,
                 p.product_category_name)       AS product_category_name_english,
        COUNT(*)                                AS items_sold,
        ROW_NUMBER() OVER (
            PARTITION BY oi.seller_id
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM order_items AS oi
    JOIN products  AS p ON p.product_id = oi.product_id
    LEFT JOIN product_category_name_translation AS t
           ON t.product_category_name = p.product_category_name
    GROUP BY oi.seller_id, product_category_name_english
),
top_category AS (
    SELECT seller_id, product_category_name_english
    FROM category_rank
    WHERE rn = 1
)
SELECT
    i.seller_id,
    s.seller_city                                AS seller_name,
    tc.product_category_name_english,
    i.total_units_sold,
    ROUND(i.total_sales,4)                       AS total_sales,
    ROUND(i.average_item_price,4)                AS average_item_price,
    ROUND(r.average_review_score,4)              AS average_review_score,
    ROUND(p.average_packing_time_days,4)         AS average_packing_time_days
FROM item_stats  AS i
JOIN sellers     AS s  ON s.seller_id = i.seller_id
LEFT JOIN review_stats  AS r ON r.seller_id = i.seller_id
LEFT JOIN packing_stats AS p ON p.seller_id = i.seller_id
LEFT JOIN top_category  AS tc ON tc.seller_id = i.seller_id
WHERE i.total_units_sold > 100
ORDER BY i.total_units_sold DESC,
         i.seller_id;