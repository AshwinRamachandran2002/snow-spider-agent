WITH item_details AS (
    /* every item sold, with its seller, order and category (in English) */
    SELECT
        oi.seller_id,
        oi.order_id,
        oi.price,
        COALESCE(pcnt."product_category_name_english",
                 p."product_category_name")                            AS category_en
    FROM "order_items"  oi
    JOIN "products"     p    ON p."product_id" = oi."product_id"
    LEFT JOIN "product_category_name_translation" pcnt
           ON pcnt."product_category_name" = p."product_category_name"
),
seller_basic AS (
    /* core sales figures – keep only sellers with >100 items sold */
    SELECT
        seller_id,
        COUNT(*)                               AS total_items_sold,
        ROUND(SUM(price),4)                    AS total_sales_amount,
        ROUND(AVG(price),4)                    AS avg_item_price
    FROM item_details
    GROUP BY seller_id
    HAVING COUNT(*) > 100
),
seller_reviews AS (
    /* average review score per seller */
    SELECT
        id.seller_id,
        ROUND(AVG(orv.review_score),4)         AS avg_review_score
    FROM          item_details  id
    JOIN "orders"          o   ON o."order_id" = id."order_id"
    JOIN "order_reviews"  orv ON orv."order_id" = o."order_id"
    GROUP BY id.seller_id
),
packing_times AS (
    /* average packing time (approved -> handed to carrier) in days */
    SELECT
        id.seller_id,
        ROUND(AVG(
              julianday(o.order_delivered_carrier_date) -
              julianday(o.order_approved_at)
        ),4)                                   AS avg_packing_time_days
    FROM          item_details id
    JOIN "orders" o
         ON o."order_id" = id."order_id"
    WHERE o.order_delivered_carrier_date IS NOT NULL
      AND o.order_approved_at            IS NOT NULL
    GROUP BY id.seller_id
),
category_totals AS (
    /* items sold per seller & category */
    SELECT
        seller_id,
        category_en,
        COUNT(*)                              AS items_in_category
    FROM item_details
    GROUP BY seller_id, category_en
),
top_category AS (
    /* pick the category (English) with the highest volume for each seller */
    SELECT
        ct1.seller_id,
        ct1.category_en
    FROM category_totals ct1
    JOIN (
        SELECT seller_id,
               MAX(items_in_category) AS max_items
        FROM category_totals
        GROUP BY seller_id
    ) ct2
    ON ct1.seller_id = ct2.seller_id
   AND ct1.items_in_category = ct2.max_items
)
SELECT
    sb.seller_id,
    sb.total_items_sold,
    sb.total_sales_amount,
    sb.avg_item_price,
    sr.avg_review_score,
    pt.avg_packing_time_days,
    tc.category_en   AS top_category_by_volume
FROM seller_basic  sb
LEFT JOIN seller_reviews sr ON sr.seller_id = sb.seller_id
LEFT JOIN packing_times pt  ON pt.seller_id  = sb.seller_id
LEFT JOIN top_category tc   ON tc.seller_id  = sb.seller_id
ORDER BY sb.total_items_sold DESC, sb.seller_id;