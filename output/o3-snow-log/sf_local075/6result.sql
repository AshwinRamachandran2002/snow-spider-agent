/*  Breakdown of product-level engagement metrics
    – views, add-to-carts, abandonments and purchases –
    excluding the generic pages whose page_id is in (1,2,12,13)           */

WITH base AS (   -- every product event we care about
    SELECT
        h."product_id",
        h."page_name"                       AS "product_name",
        e."event_type",
        e."cookie_id",
        e."visit_id"
    FROM   BANK_SALES_TRADING.BANK_SALES_TRADING.SHOPPING_CART_EVENTS            e
    JOIN   BANK_SALES_TRADING.BANK_SALES_TRADING.SHOPPING_CART_PAGE_HIERARCHY    h
           ON e."page_id" = h."page_id"
    WHERE  e."page_id" NOT IN (1,2,12,13)          -- filter out the unwanted pages
      AND  h."product_id" IS NOT NULL              -- keep only real products
),

/* simple counts of each event type per product */
summary AS (
    SELECT
        "product_id",
        "product_name",
        COUNT_IF("event_type" = 1)  AS view_cnt,
        COUNT_IF("event_type" = 2)  AS add_to_cart_cnt,
        COUNT_IF("event_type" = 3)  AS purchase_cnt
    FROM   base
    GROUP BY "product_id", "product_name"
),

/* add-to-cart events that were never followed by a purchase
   in the same cookie + visit for the same product            */
abandons AS (
    WITH adds AS (
        SELECT "cookie_id", "visit_id", "product_id"
        FROM   base
        WHERE  "event_type" = 2
    ),
    buys AS (
        SELECT "cookie_id", "visit_id", "product_id"
        FROM   base
        WHERE  "event_type" = 3
    )
    SELECT  a."product_id",
            COUNT(*) AS abandoned_cart_cnt
    FROM    adds a
    LEFT    JOIN buys b
           ON  a."cookie_id"  = b."cookie_id"
           AND a."visit_id"   = b."visit_id"
           AND a."product_id" = b."product_id"
    WHERE   b."product_id" IS NULL
    GROUP BY a."product_id"
)

/* final report */
SELECT  s."product_id",
        s."product_name",
        s.view_cnt,
        s.add_to_cart_cnt,
        COALESCE(a.abandoned_cart_cnt,0) AS abandoned_cart_cnt,
        s.purchase_cnt
FROM    summary  s
LEFT    JOIN abandons a
       ON s."product_id" = a."product_id"
ORDER BY s."product_id";