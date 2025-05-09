/* -----------------------------------------------------------
   Comprehensive performance report per seller
   – Total sales, average item price, average review score,
     average packing-time (hours) and best-selling category (EN).
   Only sellers with > 100 items sold are returned.
------------------------------------------------------------*/
WITH
/* 1. Base order-items information */
items AS (
    SELECT
        oi."seller_id",
        oi."order_id",
        oi."product_id",
        oi."price"
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_ITEMS" oi
),

/* 2. Core sales metrics per seller */
seller_sales AS (
    SELECT
        "seller_id",
        COUNT(*)                                       AS qty_sold,
        SUM("price")                                   AS total_sales_value,
        AVG("price")                                   AS avg_item_price
    FROM items
    GROUP BY "seller_id"
),

/* 3. Average review score per seller */
seller_reviews AS (
    SELECT
        i."seller_id",
        AVG(r."review_score")                          AS avg_review_score
    FROM items                    i
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES."ORDERS"        o  ON i."order_id" = o."order_id"
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_REVIEWS" r  ON r."order_id" = o."order_id"
    WHERE r."review_score" IS NOT NULL
    GROUP BY i."seller_id"
),

/* 4. Average packing time (approval ➔ carrier pick-up) per seller */
seller_pack AS (
    SELECT
        i."seller_id",
        AVG(
            DATEDIFF(
                'hour',
                TO_TIMESTAMP(o."order_approved_at"),
                TO_TIMESTAMP(o."order_delivered_carrier_date")
            )
        )                                              AS avg_packing_time_hours
    FROM items                i
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES."ORDERS" o
          ON i."order_id" = o."order_id"
    WHERE o."order_approved_at"            IS NOT NULL
      AND o."order_delivered_carrier_date" IS NOT NULL
      AND o."order_approved_at"            <> ''
      AND o."order_delivered_carrier_date" <> ''
    GROUP BY i."seller_id"
),

/* 5. Identify the best-selling product category (English) per seller */
seller_top_cat AS (
    SELECT
        i."seller_id",
        COALESCE(t."product_category_name_english",
                 p."product_category_name")            AS category_en,
        COUNT(*)                                       AS items_in_category,
        ROW_NUMBER() OVER (
            PARTITION BY i."seller_id"
            ORDER BY COUNT(*) DESC
        )                                              AS rn
    FROM items                               i
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES."PRODUCTS" p
          ON i."product_id" = p."product_id"
    LEFT JOIN ELECTRONIC_SALES.ELECTRONIC_SALES."PRODUCT_CATEGORY_NAME_TRANSLATION" t
          ON p."product_category_name" = t."product_category_name"
    GROUP BY
        i."seller_id",
        COALESCE(t."product_category_name_english",
                 p."product_category_name")
    QUALIFY rn = 1           -- keep only the top category per seller
)

/* 6. Final report – combine all metrics & filter */
SELECT
    s."seller_id",
    s.qty_sold,
    s.total_sales_value,
    ROUND(s.avg_item_price,          4)  AS avg_item_price,
    ROUND(r.avg_review_score,        4)  AS avg_review_score,
    ROUND(p.avg_packing_time_hours,  4)  AS avg_packing_time_hours,
    c.category_en                     AS top_category_en
FROM seller_sales  s
LEFT JOIN seller_reviews r  ON s."seller_id" = r."seller_id"
LEFT JOIN seller_pack    p  ON s."seller_id" = p."seller_id"
LEFT JOIN seller_top_cat c  ON s."seller_id" = c."seller_id"
WHERE s.qty_sold > 100
ORDER BY s.total_sales_value DESC NULLS LAST;