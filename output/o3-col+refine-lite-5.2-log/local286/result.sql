/* ------------------------------------------------------------
   Combined single‑statement report:
   – Seller‑level performance (only sellers with >100 items sold)
   – Top 10 product categories (English) by quantity sold
   ------------------------------------------------------------ */
WITH
sales AS (
    SELECT oi."seller_id",
           COUNT(*)  AS qty_items_sold,
           SUM(oi."price") AS total_sales_value,
           AVG(oi."price") AS avg_item_price
    FROM   "order_items" AS oi
    GROUP  BY oi."seller_id"
    HAVING COUNT(*) > 100
),
reviews AS (
    SELECT oi."seller_id",
           AVG(rv."review_score") AS avg_review_score
    FROM   "order_items"   AS oi
    JOIN   "order_reviews" AS rv
           ON oi."order_id" = rv."order_id"
    GROUP  BY oi."seller_id"
),
packing AS (
    SELECT oi."seller_id",
           AVG(julianday(oi."shipping_limit_date")
               - julianday(o."order_purchase_timestamp")) AS avg_packing_days
    FROM   "order_items" AS oi
    JOIN   "orders"      AS o
           ON oi."order_id" = o."order_id"
    GROUP  BY oi."seller_id"
),
seller_report AS (
    SELECT s."seller_id"                     AS identifier,
           s."seller_city",
           s."seller_state",
           sl.qty_items_sold,
           ROUND(sl.total_sales_value,4)     AS total_sales_value,
           ROUND(sl.avg_item_price,4)        AS avg_item_price,
           ROUND(rv.avg_review_score,4)      AS avg_review_score,
           ROUND(pk.avg_packing_days,4)      AS avg_packing_days,
           'seller'                          AS section
    FROM   sales  AS sl
    JOIN   "sellers" AS s ON s."seller_id" = sl."seller_id"
    LEFT JOIN reviews AS rv ON rv."seller_id" = sl."seller_id"
    LEFT JOIN packing AS pk ON pk."seller_id" = sl."seller_id"
),
top_categories AS (
    SELECT t."product_category_name_english" AS identifier,
           NULL          AS seller_city,
           NULL          AS seller_state,
           COUNT(*)      AS qty_items_sold,
           NULL          AS total_sales_value,
           NULL          AS avg_item_price,
           NULL          AS avg_review_score,
           NULL          AS avg_packing_days,
           'category'    AS section
    FROM   "order_items" AS oi
    JOIN   "products"    AS p ON oi."product_id" = p."product_id"
    JOIN   "product_category_name_translation" AS t
           ON p."product_category_name" = t."product_category_name"
    GROUP  BY t."product_category_name_english"
    ORDER  BY qty_items_sold DESC
    LIMIT 10
)
SELECT *
FROM   seller_report

UNION ALL

SELECT *
FROM   top_categories
ORDER BY section, qty_items_sold DESC, identifier;