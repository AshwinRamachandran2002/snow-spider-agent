WITH
-- 1. Basic sales metrics per seller
seller_basic AS (
    SELECT
        oi.seller_id,
        COUNT(*)                                    AS total_items_sold,
        SUM(oi.price)                              AS total_sales,
        AVG(oi.price)                              AS avg_item_price
    FROM order_items AS oi
    GROUP BY oi.seller_id
),

-- 2. Average review score per seller (use one record per order to avoid duplicates)
seller_reviews AS (
    SELECT
        so.seller_id,
        AVG(orv.review_score)                      AS avg_review_score
    FROM (SELECT DISTINCT seller_id, order_id
          FROM order_items) AS so
    JOIN order_reviews AS orv USING (order_id)
    GROUP BY so.seller_id
),

-- 3. Average packing time (days) per seller:  approved → handed to carrier
seller_packing AS (
    SELECT
        sop.seller_id,
        AVG(julianday(o.order_delivered_carrier_date) -
            julianday(o.order_approved_at))        AS avg_packing_days
    FROM (SELECT DISTINCT seller_id, order_id
          FROM order_items) AS sop
    JOIN orders AS o     USING (order_id)
    WHERE o.order_delivered_carrier_date IS NOT NULL
      AND o.order_approved_at            IS NOT NULL
    GROUP BY sop.seller_id
),

-- 4. Count of items sold per seller & category (in English)
seller_category_count AS (
    SELECT
        oi.seller_id,
        pct.product_category_name_english          AS category_en,
        COUNT(*)                                   AS items_count
    FROM order_items                     AS oi
    JOIN products                        AS pr   ON pr.product_id = oi.product_id
    LEFT JOIN product_category_name_translation pct
                                                ON pct.product_category_name = pr.product_category_name
    GROUP BY oi.seller_id, category_en
),

-- 5. Pick the top‑selling category (highest quantity) per seller
seller_category_rank AS (
    SELECT
        scc.*,
        ROW_NUMBER() OVER (PARTITION BY scc.seller_id
                           ORDER BY scc.items_count DESC, scc.category_en) AS rn
    FROM seller_category_count AS scc
),
top_category AS (
    SELECT seller_id, category_en
    FROM   seller_category_rank
    WHERE  rn = 1
)

-- 6. Final report
SELECT
    sb.seller_id,
    s.seller_city,
    s.seller_state,
    sb.total_items_sold,
    ROUND(sb.total_sales,        4)  AS total_sales,
    ROUND(sb.avg_item_price,     4)  AS avg_item_price,
    ROUND(sr.avg_review_score,   4)  AS avg_review_score,
    ROUND(sp.avg_packing_days,   4)  AS avg_packing_days,
    tc.category_en                      AS top_category_english
FROM        seller_basic   AS sb
JOIN        sellers        AS s   ON s.seller_id = sb.seller_id
LEFT JOIN   seller_reviews AS sr  ON sr.seller_id = sb.seller_id
LEFT JOIN   seller_packing AS sp  ON sp.seller_id = sb.seller_id
LEFT JOIN   top_category   AS tc  ON tc.seller_id = sb.seller_id
WHERE sb.total_items_sold > 100
ORDER BY sb.total_items_sold DESC, sb.seller_id;