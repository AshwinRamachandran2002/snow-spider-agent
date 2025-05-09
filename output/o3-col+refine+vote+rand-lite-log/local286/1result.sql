WITH
seller_base AS (          -- sellers with >100 items sold and basic sales KPIs
    SELECT
        oi."seller_id",
        COUNT(*)              AS "qty_sold",
        SUM(oi."price")       AS "total_sales_value",
        AVG(oi."price")       AS "avg_item_price"
    FROM   "order_items" AS oi
    GROUP  BY oi."seller_id"
    HAVING COUNT(*) > 100
),
seller_reviews AS (        -- average review score per seller
    SELECT
        oi."seller_id",
        ROUND(AVG(r."review_score"), 2) AS "avg_review_score"
    FROM   "order_items"  AS oi
    JOIN   "order_reviews" AS r
      ON   r."order_id" = oi."order_id"
    GROUP  BY oi."seller_id"
),
seller_packing AS (        -- average packing time (hours) per seller
    SELECT
        oi."seller_id",
        ROUND(
              AVG(
                  (julianday(o."order_delivered_carrier_date") -
                   julianday(o."order_approved_at")) * 24
              ), 2) AS "avg_packing_time_hrs"
    FROM   "order_items" AS oi
    JOIN   "orders"      AS o
      ON   o."order_id" = oi."order_id"
    WHERE  o."order_delivered_carrier_date" IS NOT NULL
      AND  o."order_approved_at"            IS NOT NULL
    GROUP  BY oi."seller_id"
),
top_categories AS (        -- top-selling product categories (English)
    SELECT
        t."product_category_name_english",
        COUNT(*) AS "items_sold"
    FROM   "order_items" AS oi
    JOIN   "products"    AS p
      ON   p."product_id" = oi."product_id"
    LEFT  JOIN "product_category_name_translation" AS t
      ON   t."product_category_name" = p."product_category_name"
    GROUP  BY t."product_category_name_english"
    ORDER  BY COUNT(*) DESC
    LIMIT 5
),
top_cat_list AS (          -- single row holding a comma-separated list of top categories
    SELECT
        GROUP_CONCAT("product_category_name_english", ', ') AS "top_categories"
    FROM   top_categories
)

SELECT
    sb."seller_id",
    sb."qty_sold",
    ROUND(sb."total_sales_value", 4) AS "total_sales_value",
    ROUND(sb."avg_item_price", 4)    AS "avg_item_price",
    sr."avg_review_score",
    sp."avg_packing_time_hrs",
    tcl."top_categories"             -- highlights the highest-selling categories
FROM   seller_base  AS sb
LEFT   JOIN seller_reviews AS sr ON sr."seller_id" = sb."seller_id"
LEFT   JOIN seller_packing AS sp ON sp."seller_id" = sb."seller_id"
CROSS  JOIN top_cat_list  AS tcl
ORDER  BY sb."total_sales_value" DESC;