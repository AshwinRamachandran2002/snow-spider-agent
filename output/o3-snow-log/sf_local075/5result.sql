/*  Product-level funnel metrics
    – Views, Add-to-Cart, Left-in-Cart and Purchases
    – Pages 1,2,12,13 are excluded                                     */

WITH filtered_events AS (       -- keep only relevant pages
    SELECT
        "visit_id",
        "cookie_id",
        "page_id",
        "event_type"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS"
    WHERE "page_id" NOT IN (1, 2, 12, 13)
),

add_cart AS (                   -- every add-to-cart action
    SELECT
        "visit_id",
        "cookie_id",
        "page_id"
    FROM filtered_events
    WHERE "event_type" = 2
),

purchases AS (                  -- distinct purchases (one per visit/cookie/page)
    SELECT DISTINCT
        "visit_id",
        "cookie_id",
        "page_id"
    FROM filtered_events
    WHERE "event_type" = 3
),

left_in_cart AS (               -- add-to-cart actions with NO matching purchase
    SELECT
        a."page_id",
        COUNT(*) AS "left_in_cart"
    FROM add_cart a
    LEFT JOIN purchases p
           ON  a."visit_id" = p."visit_id"
           AND a."cookie_id" = p."cookie_id"
           AND a."page_id"   = p."page_id"
    WHERE p."visit_id" IS NULL
    GROUP BY a."page_id"
),

summary AS (                    -- counts for each event type
    SELECT
        "page_id",
        COUNT(CASE WHEN "event_type" = 1 THEN 1 END) AS "views",
        COUNT(CASE WHEN "event_type" = 2 THEN 1 END) AS "add_to_cart",
        COUNT(CASE WHEN "event_type" = 3 THEN 1 END) AS "purchases"
    FROM filtered_events
    GROUP BY "page_id"
)

SELECT
    s."page_id",
    ph."page_name",
    ph."product_id",
    COALESCE(s."views",0)        AS "views",
    COALESCE(s."add_to_cart",0)  AS "add_to_cart",
    COALESCE(l."left_in_cart",0) AS "left_in_cart",
    COALESCE(s."purchases",0)    AS "purchases"
FROM summary s
LEFT JOIN left_in_cart l
       ON s."page_id" = l."page_id"
LEFT JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_PAGE_HIERARCHY" ph
       ON s."page_id" = ph."page_id"
ORDER BY s."page_id";