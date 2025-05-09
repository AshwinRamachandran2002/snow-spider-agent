WITH
    purchase_visits AS (
        SELECT DISTINCT "visit_id"
        FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS"
        WHERE "event_type" = 3
    ),
    product_views AS (
        SELECT 
            p."product_id", 
            COUNT(*) AS "views"
        FROM 
            "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS" e
        JOIN 
            "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_PAGE_HIERARCHY" p 
            ON e."page_id" = p."page_id"
        WHERE 
            e."event_type" = 1 
            AND e."page_id" NOT IN (1, 2, 12, 13)
        GROUP BY 
            p."product_id"
    ),
    product_adds AS (
        SELECT 
            p."product_id", 
            COUNT(*) AS "adds_to_cart"
        FROM 
            "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS" e
        JOIN 
            "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_PAGE_HIERARCHY" p 
            ON e."page_id" = p."page_id"
        WHERE 
            e."event_type" = 2 
            AND e."page_id" NOT IN (1, 2, 12, 13)
        GROUP BY 
            p."product_id"
    ),
    product_purchases AS (
        SELECT 
            p."product_id", 
            COUNT(*) AS "purchases"
        FROM 
            "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS" e
        JOIN 
            "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_PAGE_HIERARCHY" p 
            ON e."page_id" = p."page_id"
        JOIN 
            purchase_visits pv 
            ON e."visit_id" = pv."visit_id"
        WHERE 
            e."event_type" = 2 
            AND e."page_id" NOT IN (1, 2, 12, 13)
        GROUP BY 
            p."product_id"
    )
SELECT
    v."product_id",
    v."views",
    a."adds_to_cart",
    (a."adds_to_cart" - COALESCE(pu."purchases", 0)) AS "left_in_cart",
    COALESCE(pu."purchases", 0) AS "purchases"
FROM 
    product_views v
LEFT JOIN 
    product_adds a ON v."product_id" = a."product_id"
LEFT JOIN 
    product_purchases pu ON v."product_id" = pu."product_id"
ORDER BY 
    v."product_id";