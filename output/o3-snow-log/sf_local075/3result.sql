/* --------------------------------------------------------------
   Breakdown per product: views, add-to-cart, abandoned carts, and
   completed purchases – excluding page_id 1,2,12,13
----------------------------------------------------------------*/
WITH product_events AS (          -- map every kept event to a product
    SELECT
        e."visit_id",
        h."product_id",
        e."event_type"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS"        e
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_PAGE_HIERARCHY" h
          ON e."page_id" = h."page_id"
    WHERE e."page_id" NOT IN (1,2,12,13)
),
/* 1. simple counts ---------------------------------------------------------*/
views AS (
    SELECT "product_id", COUNT(*)                AS "views"
    FROM product_events
    WHERE "event_type" = 1                       -- Page View
    GROUP BY "product_id"
),
addc AS (
    SELECT "product_id", COUNT(*)                AS "add_to_cart"
    FROM product_events
    WHERE "event_type" = 2                       -- Add to Cart
    GROUP BY "product_id"
),
buy AS (
    SELECT "product_id", COUNT(*)                AS "purchases"
    FROM product_events
    WHERE "event_type" = 3                       -- Purchase
    GROUP BY "product_id"
),
/* 2. abandoned-cart logic ---------------------------------------------------*/
abandon AS (
    /* every visit-product pair with an Add-to-Cart but *no* Purchase */
    SELECT
        ac."product_id",
        COUNT(*)                                 AS "abandoned_cart"
    FROM (
        SELECT DISTINCT "visit_id", "product_id"
        FROM product_events
        WHERE "event_type" = 2                   -- Add to Cart
    )  ac
    LEFT JOIN (
        SELECT DISTINCT "visit_id", "product_id"
        FROM product_events
        WHERE "event_type" = 3                   -- Purchase
    )  pu
           ON ac."visit_id"  = pu."visit_id"
          AND ac."product_id" = pu."product_id"
    WHERE pu."visit_id" IS NULL                  -- no purchase happened
    GROUP BY ac."product_id"
)
/* 3. bring everything together ---------------------------------------------*/
SELECT
    COALESCE(v."product_id",
             a."product_id",
             d."product_id",
             b."product_id")                     AS "product_id",

    COALESCE(v."views",          0)              AS "views",
    COALESCE(a."add_to_cart",    0)              AS "add_to_cart",
    COALESCE(d."abandoned_cart", 0)              AS "abandoned_cart",
    COALESCE(b."purchases",      0)              AS "purchases"

FROM views     v
FULL OUTER JOIN addc     a ON v."product_id" = a."product_id"
FULL OUTER JOIN abandon   d ON COALESCE(v."product_id",a."product_id") = d."product_id"
FULL OUTER JOIN buy       b ON COALESCE(v."product_id",a."product_id",d."product_id") = b."product_id"

ORDER BY "views" DESC NULLS LAST;