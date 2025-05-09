/* Comprehensive performance report for sellers
   – only sellers with more than 100 items sold                */

WITH seller_perf AS (
    /* Core commercial metrics */
    SELECT
        oi."seller_id",
        COUNT(*)                                      AS "total_units",
        ROUND(SUM(oi."price"), 4)                     AS "total_sales",
        ROUND(AVG(oi."price"), 4)                     AS "avg_item_price"
    FROM   "order_items" AS oi
    GROUP  BY oi."seller_id"
    HAVING COUNT(*) > 100
),

seller_reviews AS (
    /* Average review score per seller */
    SELECT
        oi."seller_id",
        ROUND(AVG(orv."review_score"), 4)             AS "avg_review_score"
    FROM   "order_items"   AS oi
    JOIN   "order_reviews" AS orv
           ON orv."order_id" = oi."order_id"
    GROUP  BY oi."seller_id"
),

seller_packing AS (
    /* Average packing time (days between approval and carrier scan) */
    SELECT
        oi."seller_id",
        ROUND(
            AVG(
                julianday(o."order_delivered_carrier_date")
              - julianday(o."order_approved_at")
            ), 4
        )                                             AS "avg_packing_days"
    FROM   "order_items" AS oi
    JOIN   "orders"      AS o
           ON o."order_id" = oi."order_id"
    GROUP  BY oi."seller_id"
),

seller_top_cat AS (
    /* Highest-volume product category (English) for each seller */
    SELECT
        "seller_id",
        "product_category_name_english",
        "qty_sold"
    FROM (
        SELECT
            oi."seller_id",
            pct."product_category_name_english",
            COUNT(*)                                  AS "qty_sold",
            RANK() OVER (
                PARTITION BY oi."seller_id"
                ORDER BY COUNT(*) DESC
            )                                         AS rnk
        FROM   "order_items" AS oi
        JOIN   "products"    AS p
               ON p."product_id" = oi."product_id"
        JOIN   "product_category_name_translation" AS pct
               ON pct."product_category_name" = p."product_category_name"
        GROUP  BY oi."seller_id",
                 pct."product_category_name_english"
    )
    WHERE rnk = 1
)

SELECT
    sp."seller_id",
    sp."total_units",
    sp."total_sales",
    sp."avg_item_price",
    sr."avg_review_score",
    spk."avg_packing_days",
    stc."product_category_name_english"  AS "top_category_en",
    stc."qty_sold"                       AS "top_category_units"
FROM   seller_perf   AS sp
LEFT   JOIN seller_reviews AS sr   ON sr."seller_id"  = sp."seller_id"
LEFT   JOIN seller_packing AS spk  ON spk."seller_id" = sp."seller_id"
LEFT   JOIN seller_top_cat AS stc  ON stc."seller_id" = sp."seller_id"
ORDER  BY sp."total_sales" DESC;