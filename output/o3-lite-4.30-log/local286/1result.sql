WITH seller_stats AS (
    SELECT
        oi."seller_id",
        COUNT(*)                                                    AS total_units_sold,
        SUM(oi."price")                                             AS total_sales,
        AVG(oi."price")                                             AS average_item_price,
        AVG(julianday(oi."shipping_limit_date") -
            julianday(o."order_purchase_timestamp"))                AS average_packing_time_days,
        AVG(r."review_score")                                       AS average_review_score
    FROM   "order_items"  AS oi
    JOIN   "orders"       AS o  USING ("order_id")
    LEFT JOIN "order_reviews" AS r USING ("order_id")
    GROUP  BY oi."seller_id"
    HAVING COUNT(*) > 100                 -- sellers with >100 items sold
),
top_category AS (
    SELECT
        seller_id,
        product_category_name_english
    FROM (
        SELECT
            oi."seller_id",
            t."product_category_name_english",
            COUNT(*)                                           AS qty,
            ROW_NUMBER() OVER (PARTITION BY oi."seller_id"
                               ORDER BY COUNT(*) DESC)         AS rn
        FROM   "order_items" AS oi
        JOIN   "products"    AS p  USING ("product_id")
        JOIN   "product_category_name_translation" AS t
               USING ("product_category_name")
        GROUP  BY oi."seller_id", t."product_category_name_english"
    )
    WHERE rn = 1                    -- keep the top‑selling category
)
SELECT
       ss."seller_id",
       s."seller_city"                               AS seller_name,
       tc."product_category_name_english",
       ss.total_units_sold,
       ROUND(ss.total_sales,              4) AS total_sales,
       ROUND(ss.average_item_price,       4) AS average_item_price,
       ROUND(ss.average_review_score,     4) AS average_review_score,
       ROUND(ss.average_packing_time_days,4) AS average_packing_time_days
FROM   seller_stats AS ss
LEFT JOIN "sellers"      AS s  ON s."seller_id" = ss."seller_id"
LEFT JOIN top_category   AS tc ON tc."seller_id" = ss."seller_id"
ORDER BY ss.total_units_sold DESC,
         ss."seller_id";