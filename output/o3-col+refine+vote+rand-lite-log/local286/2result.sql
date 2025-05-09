WITH seller_sales AS (          -- overall sales > 100 items
    SELECT
        oi."seller_id",
        COUNT(*)                AS qty_sold,
        SUM(oi."price")         AS total_sales_value,
        AVG(oi."price")         AS avg_item_price
    FROM "order_items" AS oi
    GROUP BY oi."seller_id"
    HAVING COUNT(*) > 100
),
seller_reviews AS (             -- average review score (distinct orders)
    SELECT
        s."seller_id",
        AVG(s."review_score")   AS avg_review_score
    FROM (
        SELECT DISTINCT
               oi."seller_id",
               rv."order_id",
               rv."review_score"
        FROM "order_items"  AS oi
        JOIN "order_reviews" AS rv
          ON rv."order_id" = oi."order_id"
    ) AS s
    GROUP BY s."seller_id"
),
seller_packing AS (             -- average packing time (days)
    SELECT
        oi."seller_id",
        AVG(JULIANDAY(o."order_delivered_carrier_date")
           -JULIANDAY(o."order_approved_at"))  AS avg_packing_time_days
    FROM "order_items" AS oi
    JOIN "orders"      AS o
      ON o."order_id" = oi."order_id"
    WHERE o."order_delivered_carrier_date" IS NOT NULL
      AND o."order_approved_at"           IS NOT NULL
    GROUP BY oi."seller_id"
),
category_qty AS (               -- quantity by category (English)
    SELECT
        oi."seller_id",
        COALESCE(pct."product_category_name_english",'unknown')
                                   AS product_category_name_english,
        COUNT(*)                   AS qty_sold
    FROM "order_items" AS oi
    JOIN "products"  AS p
      ON p."product_id" = oi."product_id"
    LEFT JOIN "product_category_name_translation" AS pct
      ON pct."product_category_name" = p."product_category_name"
    GROUP BY oi."seller_id", product_category_name_english
),
category_max AS (               -- highest–volume category per seller
    SELECT
        seller_id,
        MAX(qty_sold) AS max_qty
    FROM category_qty
    GROUP BY seller_id
),
top_category AS (               -- tie-safe join to get the name & qty
    SELECT
        cq."seller_id",
        cq."product_category_name_english",
        cq."qty_sold"
    FROM category_qty  AS cq
    JOIN category_max  AS cm
      ON cm."seller_id" = cq."seller_id"
     AND cm."max_qty"   = cq."qty_sold"
)
SELECT
    ss."seller_id",
    ss."qty_sold",
    ss."total_sales_value",
    ROUND(ss."avg_item_price",4)        AS avg_item_price,
    ROUND(sr."avg_review_score",4)      AS avg_review_score,
    ROUND(sp."avg_packing_time_days",4) AS avg_packing_time_days,
    tc."product_category_name_english"  AS top_product_category,
    tc."qty_sold"                       AS top_category_qty
FROM  seller_sales  AS ss
LEFT JOIN seller_reviews AS sr ON sr."seller_id" = ss."seller_id"
LEFT JOIN seller_packing AS sp ON sp."seller_id" = ss."seller_id"
LEFT JOIN top_category   AS tc ON tc."seller_id" = ss."seller_id"
ORDER BY ss."total_sales_value" DESC;