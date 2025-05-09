WITH purchases_visits AS (
    SELECT DISTINCT e."visit_id"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS" e
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENT_IDENTIFIER" i
        ON e."event_type" = i."event_type"
    WHERE i."event_name" = 'Purchase'
),
events_with_products AS (
    SELECT e.*, i."event_name", p."product_id"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS" e
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENT_IDENTIFIER" i
        ON e."event_type" = i."event_type"
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_PAGE_HIERARCHY" p
        ON e."page_id" = p."page_id"
    WHERE e."page_id" NOT IN (1, 2, 12, 13)
),
views_cte AS (
    SELECT "product_id", COUNT(*) AS views
    FROM events_with_products
    WHERE "event_name" = 'Page View'
    GROUP BY "product_id"
),
adds_cte AS (
    SELECT "product_id", COUNT(*) AS adds_to_cart
    FROM events_with_products
    WHERE "event_name" = 'Add to Cart'
    GROUP BY "product_id"
),
purchases_cte AS (
    SELECT "product_id", COUNT(*) AS purchases
    FROM events_with_products ewp
    WHERE ewp."event_name" = 'Add to Cart'
      AND ewp."visit_id" IN (SELECT "visit_id" FROM purchases_visits)
    GROUP BY "product_id"
)
SELECT 
    COALESCE(v."product_id", a."product_id", p."product_id") AS "product_id",
    COALESCE(v.views, 0) AS "views",
    COALESCE(a.adds_to_cart, 0) AS "adds_to_cart",
    (COALESCE(a.adds_to_cart, 0) - COALESCE(p.purchases, 0)) AS "left_in_cart",
    COALESCE(p.purchases, 0) AS "purchases"
FROM views_cte v
FULL OUTER JOIN adds_cte a ON v."product_id" = a."product_id"
FULL OUTER JOIN purchases_cte p ON COALESCE(v."product_id", a."product_id") = p."product_id"
ORDER BY "product_id";