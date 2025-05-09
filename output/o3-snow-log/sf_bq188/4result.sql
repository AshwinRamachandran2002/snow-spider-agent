/*  Goal:  Find the product-category with the greatest number of items sold,   */
/*         then calculate the average minutes a shopper stays on each product */
/*         page (time until the very next event in the same session).          */
WITH purchase_counts AS (   ---------------------------------------------------
    SELECT
        p."category",
        COUNT(*) AS purchase_qty
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    GROUP BY p."category"
),

top_category AS (           ---------------------------------------------------
    SELECT "category"
    FROM   purchase_counts
    ORDER BY purchase_qty DESC NULLS LAST
    LIMIT 1
),

product_page_events AS (    ---------------------------------------------------
    /* Identify every product-page view that belongs to the top category.     */
    /* A product page URI is like '/product/<id or sku>'                      */
    SELECT
        e."session_id",
        e."created_at",
        p."category"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"   e
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
          ON (  SPLIT_PART(e."uri", '/', 3) = p."sku"
            OR  TRY_TO_NUMBER(SPLIT_PART(e."uri", '/', 3)) = p."id" )
    WHERE e."uri" LIKE '/product/%'
      AND p."category" = (SELECT "category" FROM top_category)
),

event_with_next AS (        ---------------------------------------------------
    /* For each product view, find the timestamp of the very next event       */
    SELECT
        "category",
        "session_id",
        "created_at",
        LEAD("created_at")
            OVER (PARTITION BY "session_id" ORDER BY "created_at") AS next_created_at
    FROM product_page_events
),

time_deltas AS (            ---------------------------------------------------
    /* Convert microsecond differences to minutes                            */
    SELECT
        "category",
        (next_created_at - "created_at") / 1000000.0 / 60  AS minutes_spent
    FROM event_with_next
    WHERE next_created_at IS NOT NULL
)

SELECT                      ---------------------------------------------------
    "category",
    ROUND(AVG(minutes_spent), 4) AS average_time_minutes
FROM time_deltas
GROUP BY "category";