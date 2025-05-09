WITH seller_sales AS (
    SELECT
        oi."seller_id",
        COUNT(*)                         AS products_sold,
        SUM(oi."price")                  AS total_sales,
        AVG(oi."price")                  AS avg_item_price
    FROM "order_items" oi
    GROUP BY oi."seller_id"
    HAVING COUNT(*) > 100
),
seller_reviews AS (
    SELECT
        oi."seller_id",
        AVG(orv."review_score")          AS avg_review_score
    FROM "order_items"  oi
    JOIN "order_reviews" orv
         ON oi."order_id" = orv."order_id"
    GROUP BY oi."seller_id"
),
seller_packing AS (
    SELECT
        oi."seller_id",
        AVG(
            julianday(o."order_delivered_carrier_date")
          - julianday(o."order_approved_at")
        )                                AS avg_packing_time_days
    FROM "order_items" oi
    JOIN "orders" o
         ON oi."order_id" = o."order_id"
    WHERE o."order_delivered_carrier_date" IS NOT NULL
      AND o."order_approved_at"            IS NOT NULL
    GROUP BY oi."seller_id"
),
seller_top_category AS (
    SELECT seller_id,
           category,
           items_sold
    FROM (
        SELECT
            oi."seller_id",
            COALESCE(pcnt."product_category_name_english", p."product_category_name")
                                             AS category,
            COUNT(*)                         AS items_sold,
            ROW_NUMBER() OVER (
                PARTITION BY oi."seller_id"
                ORDER BY COUNT(*) DESC
            )                                AS rn
        FROM "order_items" oi
        LEFT JOIN "products" p
               ON oi."product_id" = p."product_id"
        LEFT JOIN "product_category_name_translation" pcnt
               ON p."product_category_name" = pcnt."product_category_name"
        GROUP BY oi."seller_id", category
    )
    WHERE rn = 1
)
SELECT
    ss."seller_id",
    ss.products_sold,
    ROUND(ss.total_sales,        4) AS total_sales,
    ROUND(ss.avg_item_price,     4) AS avg_item_price,
    ROUND(sr.avg_review_score,   4) AS avg_review_score,
    ROUND(sp.avg_packing_time_days,4) AS avg_packing_time_days,
    stc.category                     AS top_category_english
FROM seller_sales ss
LEFT JOIN seller_reviews    sr  ON ss."seller_id" = sr."seller_id"
LEFT JOIN seller_packing    sp  ON ss."seller_id" = sp."seller_id"
LEFT JOIN seller_top_category stc ON ss."seller_id" = stc."seller_id"
ORDER BY ss.total_sales DESC,
         ss."seller_id";