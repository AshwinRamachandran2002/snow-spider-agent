/*  Product funnel summary:
    - view_cnt          : # Page-View events
    - add_to_cart_cnt   : # Add-to-Cart events
    - left_in_cart_cnt  : # Add-to-Cart events that were NOT followed by a Purchase
    - purchase_cnt      : # Purchase events
    Pages 1,2,12,13 (home / all-products / checkout / confirmation) are excluded.
*/
WITH views AS (      -- how many times each product page was viewed
    SELECT
        "page_id",
        COUNT(*) AS view_cnt
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS"
    WHERE "event_type" = 1
      AND "page_id" NOT IN (1,2,12,13)
    GROUP BY "page_id"
),

add_cart AS (        -- how many times product was added to cart
    SELECT
        "page_id",
        COUNT(*) AS add_to_cart_cnt
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS"
    WHERE "event_type" = 2
      AND "page_id" NOT IN (1,2,12,13)
    GROUP BY "page_id"
),

purchases AS (       -- how many purchases occurred
    SELECT
        "page_id",
        COUNT(*) AS purchase_cnt
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS"
    WHERE "event_type" = 3
      AND "page_id" NOT IN (1,2,12,13)
    GROUP BY "page_id"
),

left_cart AS (       -- add-to-cart rows that were never purchased in the same visit
    WITH cart AS (
        SELECT
            "visit_id",
            "page_id"
        FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS"
        WHERE "event_type" = 2
          AND "page_id" NOT IN (1,2,12,13)
    ),
    purch AS (
        SELECT
            "visit_id",
            "page_id"
        FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS"
        WHERE "event_type" = 3
          AND "page_id" NOT IN (1,2,12,13)
    )
    SELECT
        c."page_id",
        COUNT(*) AS left_in_cart_cnt
    FROM cart  c
    LEFT JOIN purch p
           ON c."visit_id" = p."visit_id"
          AND c."page_id"  = p."page_id"
    WHERE p."page_id" IS NULL          -- means no matching purchase
    GROUP BY c."page_id"
)

SELECT
    ph."page_id",
    ph."page_name",
    COALESCE(v.view_cnt,         0) AS view_cnt,
    COALESCE(a.add_to_cart_cnt,  0) AS add_to_cart_cnt,
    COALESCE(l.left_in_cart_cnt, 0) AS left_in_cart_cnt,
    COALESCE(p.purchase_cnt,     0) AS purchase_cnt
FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_PAGE_HIERARCHY" ph
LEFT JOIN views      v ON ph."page_id" = v."page_id"
LEFT JOIN add_cart   a ON ph."page_id" = a."page_id"
LEFT JOIN left_cart  l ON ph."page_id" = l."page_id"
LEFT JOIN purchases  p ON ph."page_id" = p."page_id"
WHERE ph."page_id" NOT IN (1,2,12,13)
ORDER BY ph."page_id";