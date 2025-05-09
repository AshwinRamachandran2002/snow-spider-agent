/*--------------------------------------------------------------------
 Corrected Seller-Performance Report
   – safely handles blank date strings using TRY_TO_TIMESTAMP
--------------------------------------------------------------------*/
WITH seller_metrics AS (
    SELECT
        oi."seller_id",
        COUNT(*)                                                     AS total_items_sold,
        SUM(oi."price")                                              AS total_sales_value,
        AVG(oi."price")                                              AS avg_item_price,
        AVG(orv."review_score")                                      AS avg_review_score,
        /* packing-time: approval → shipping-limit (average days) */
        AVG(
            CASE
                WHEN TRY_TO_TIMESTAMP(o."order_approved_at") IS NOT NULL
                 AND TRY_TO_TIMESTAMP(oi."shipping_limit_date") IS NOT NULL
                THEN DATEDIFF(
                         'minute',
                         TRY_TO_TIMESTAMP(o."order_approved_at"),
                         TRY_TO_TIMESTAMP(oi."shipping_limit_date")
                     )
            END
        ) / 1440.0                                                  AS avg_packing_time_days
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_ITEMS"              oi
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES."ORDERS"                   o
          ON oi."order_id" = o."order_id"
    LEFT JOIN ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_REVIEWS"       orv
          ON oi."order_id" = orv."order_id"
    GROUP BY oi."seller_id"
    HAVING COUNT(*) > 100
),
/* ----------------------------------------------------------------- */
/* Highest-volume product category name(s) in English               */
top_categories AS (
    SELECT
        pct."product_category_name_english",
        COUNT(*) AS items_sold
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_ITEMS"                    oi
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES."PRODUCTS"                       p
          ON oi."product_id" = p."product_id"
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES."PRODUCT_CATEGORY_NAME_TRANSLATION" pct
          ON p."product_category_name" = pct."product_category_name"
    GROUP BY pct."product_category_name_english"
    QUALIFY RANK() OVER (ORDER BY COUNT(*) DESC) = 1
),
top_cat_list AS (
    SELECT LISTAGG("product_category_name_english", ', ')
           WITHIN GROUP (ORDER BY "product_category_name_english")
           AS top_product_categories
    FROM top_categories
)
/* ----------------------------------------------------------------- */
SELECT
    sm."seller_id",
    sm.total_items_sold,
    sm.total_sales_value,
    sm.avg_item_price,
    sm.avg_review_score,
    sm.avg_packing_time_days,
    tcl.top_product_categories
FROM   seller_metrics sm
CROSS  JOIN top_cat_list tcl
ORDER  BY sm.total_items_sold DESC NULLS LAST;