WITH top_category AS (   -- 1. category with the greatest number of purchased items
    SELECT p."category",
           COUNT(*) AS "total_purchase_quantity"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
      ON oi."product_id" = p."id"
    WHERE oi."status" <> 'Cancelled'                         -- exclude cancelled items
    GROUP BY p."category"
    ORDER BY "total_purchase_quantity" DESC
    LIMIT 1                                                  -- keep only the top category
),

product_events AS (      -- 2.  product‑page hits that contain a product_id in the URI
    SELECT  e."session_id",
            e."created_at",
            TRY_TO_NUMBER(
              REGEXP_SUBSTR(e."uri", '/product[s]?/([0-9]+)', 1, 1, 'e', 1)
            )  AS "product_id"
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS" e
    WHERE   e."event_type" = 'product'
      AND   REGEXP_SUBSTR(e."uri", '/product[s]?/([0-9]+)', 1, 1, 'e', 1) IS NOT NULL
),

product_events_with_next AS (   -- 3.  compute next event time within the same session
    SELECT  pe.*,
            LEAD(pe."created_at")
              OVER (PARTITION BY pe."session_id" ORDER BY pe."created_at")
            AS "next_created_at"
    FROM    product_events pe
)

SELECT
       MAX(tc."category")                AS "category_with_highest_purchases",
       MAX(tc."total_purchase_quantity") AS "total_purchase_quantity",
       AVG( (pewn."next_created_at" - pewn."created_at") / 60000000.0 )
                                         AS "avg_minutes_per_product_page_visit"
FROM   product_events_with_next  pewn
JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
       ON pewn."product_id" = p."id"
JOIN   top_category tc
       ON p."category" = tc."category"
WHERE  pewn."next_created_at" IS NOT NULL;   -- ignore last event in a session