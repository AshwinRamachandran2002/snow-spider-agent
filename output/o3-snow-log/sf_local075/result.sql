/*  Breakdown of product-level engagement metrics  
    – views, add-to-cart, left-in-cart (abandoned), and purchases            */

WITH
-- 1) total page views -------------------------------------------------------
views_cte AS (
    SELECT
        "page_id",
        COUNT(*)                       AS "views"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS"
    WHERE "event_type" = 1
      AND "page_id" NOT IN (1, 2, 12, 13)
    GROUP BY "page_id"
),

-- 2) total add-to-cart events ----------------------------------------------
atc_cte AS (
    SELECT
        "page_id",
        COUNT(*)                       AS "add_to_cart"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS"
    WHERE "event_type" = 2
      AND "page_id" NOT IN (1, 2, 12, 13)
    GROUP BY "page_id"
),

-- 3) add-to-cart events NOT followed by a purchase in the same visit+page --
left_cte AS (
    SELECT
        ac."page_id",
        COUNT(*)                       AS "left_in_cart"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS" ac
    WHERE ac."event_type" = 2
      AND ac."page_id" NOT IN (1, 2, 12, 13)
      AND NOT EXISTS (   -- no purchase for this visit + page
            SELECT 1
            FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS" pu
            WHERE pu."visit_id"  = ac."visit_id"
              AND pu."page_id"   = ac."page_id"
              AND pu."event_type" = 3
      )
    GROUP BY ac."page_id"
),

-- 4) total purchases --------------------------------------------------------
pur_cte AS (
    SELECT
        "page_id",
        COUNT(*)                       AS "purchases"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS"
    WHERE "event_type" = 3
      AND "page_id" NOT IN (1, 2, 12, 13)
    GROUP BY "page_id"
)

-- 5) combine everything with page catalogue --------------------------------
SELECT
    p."page_id",
    p."page_name",
    COALESCE(v."views",          0) AS "views",
    COALESCE(a."add_to_cart",    0) AS "add_to_cart",
    COALESCE(l."left_in_cart",   0) AS "left_in_cart",
    COALESCE(pr."purchases",     0) AS "purchases"
FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_PAGE_HIERARCHY" p
LEFT JOIN views_cte  v  ON v."page_id"  = p."page_id"
LEFT JOIN atc_cte    a  ON a."page_id"  = p."page_id"
LEFT JOIN left_cte   l  ON l."page_id"  = p."page_id"
LEFT JOIN pur_cte    pr ON pr."page_id" = p."page_id"
WHERE p."page_id" NOT IN (1, 2, 12, 13)    -- exclude unwanted pages
ORDER BY "views" DESC NULLS LAST;