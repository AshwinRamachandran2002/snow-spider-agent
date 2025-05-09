/* ---------------------------------------------------------
   Comprehensive performance report for sellers
----------------------------------------------------------*/
WITH items AS (   /* basic commercial metrics */
    SELECT
        oi."seller_id",
        COUNT(*)                         AS item_qty,
        SUM(oi."price")                  AS total_sales_value,
        AVG(oi."price")                  AS avg_item_price
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS oi
    GROUP BY oi."seller_id"
),
reviews AS (      /* customer satisfaction */
    SELECT
        oi."seller_id",
        AVG(orv."review_score")          AS avg_review_score
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS   oi
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.ORDERS        o
          ON o."order_id" = oi."order_id"
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_REVIEWS orv
          ON orv."order_id" = o."order_id"
    GROUP BY oi."seller_id"
),
packing AS (      /* operational efficiency */
    SELECT
        oi."seller_id",
        AVG(
            DATEDIFF(
                'day',
                TO_TIMESTAMP(o."order_purchase_timestamp"),
                TO_TIMESTAMP(oi."shipping_limit_date")
            )
        )                                 AS avg_packing_days
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS oi
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.ORDERS      o
          ON o."order_id" = oi."order_id"
    WHERE o."order_purchase_timestamp" IS NOT NULL
      AND oi."shipping_limit_date"     IS NOT NULL
    GROUP BY oi."seller_id"
),
category_rank AS (  /* count items per category & seller */
    SELECT
        oi."seller_id",
        COALESCE(t."product_category_name_english",
                 p."product_category_name")            AS category_english,
        COUNT(*)                                       AS category_qty,
        ROW_NUMBER() OVER (
             PARTITION BY oi."seller_id"
             ORDER BY COUNT(*) DESC
        )                                              AS rn
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS                oi
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.PRODUCTS                   p
          ON p."product_id" = oi."product_id"
    LEFT JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.PRODUCT_CATEGORY_NAME_TRANSLATION t
          ON t."product_category_name" = p."product_category_name"
    GROUP BY
        oi."seller_id",
        COALESCE(t."product_category_name_english",
                 p."product_category_name")
),
top_category AS (   /* pick best-selling category per seller */
    SELECT
        "seller_id",
        category_english          AS top_category_english,
        category_qty              AS top_category_qty
    FROM category_rank
    WHERE rn = 1
)

/* -------- final report -------- */
SELECT
    itm."seller_id",
    itm.item_qty,
    itm.total_sales_value,
    itm.avg_item_price,
    rvw.avg_review_score,
    pkg.avg_packing_days,
    tc.top_category_english,
    tc.top_category_qty
FROM items                    itm
LEFT JOIN reviews             rvw ON rvw."seller_id" = itm."seller_id"
LEFT JOIN packing             pkg ON pkg."seller_id" = itm."seller_id"
LEFT JOIN top_category        tc  ON tc."seller_id"  = itm."seller_id"
WHERE itm.item_qty > 100
ORDER BY itm.total_sales_value DESC NULLS LAST;