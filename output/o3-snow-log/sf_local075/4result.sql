/*  Breakdown of product-level funnel events
    – views, add-to-cart, purchases, left in cart
    – generic / hub pages (page_id 1,2,12,13) removed                                */

WITH
/* --- keep one clean record per product for naming --- */
page_meta AS (
    SELECT DISTINCT
           p."product_id",
           p."page_name"        AS "product_name",
           p."product_category"
    FROM   "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_PAGE_HIERARCHY" p
    WHERE  p."page_id" NOT IN (1,2,12,13)
      AND  p."product_id" IS NOT NULL
),

/* --- page views --- */
views_cte AS (
    SELECT  p."product_id",
            COUNT(*) AS "views"
    FROM    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS"         e
    JOIN    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_PAGE_HIERARCHY" p
           ON e."page_id" = p."page_id"
    WHERE   e."event_type" = 1                      -- Page View
      AND   e."page_id" NOT IN (1,2,12,13)
    GROUP BY p."product_id"
),

/* --- add-to-cart actions --- */
adds_cte AS (
    SELECT  p."product_id",
            COUNT(*) AS "adds_to_cart"
    FROM    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS"         e
    JOIN    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_PAGE_HIERARCHY" p
           ON e."page_id" = p."page_id"
    WHERE   e."event_type" = 2                      -- Add to Cart
      AND   e."page_id" NOT IN (1,2,12,13)
    GROUP BY p."product_id"
),

/* --- completed purchases --- */
purchases_cte AS (
    SELECT  p."product_id",
            COUNT(*) AS "purchases"
    FROM    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS"         e
    JOIN    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_PAGE_HIERARCHY" p
           ON e."page_id" = p."page_id"
    WHERE   e."event_type" = 3                      -- Purchase
      AND   e."page_id" NOT IN (1,2,12,13)
      AND   p."product_id" IS NOT NULL
    GROUP BY p."product_id"
),

/* --- consolidate the three funnels --- */
stats AS (
    SELECT  COALESCE(v."product_id", a."product_id", pu."product_id")        AS "product_id",
            COALESCE(v."views",        0)                                    AS "views",
            COALESCE(a."adds_to_cart", 0)                                    AS "adds_to_cart",
            COALESCE(pu."purchases",   0)                                    AS "purchases",
            COALESCE(a."adds_to_cart", 0) - COALESCE(pu."purchases", 0)      AS "left_in_cart"
    FROM        views_cte      v
    FULL JOIN   adds_cte       a  ON v."product_id" = a."product_id"
    FULL JOIN   purchases_cte  pu ON COALESCE(v."product_id", a."product_id") = pu."product_id"
)

/* --- final output with friendly product names --- */
SELECT  s."product_id",
        m."product_name",
        m."product_category",
        s."views",
        s."adds_to_cart",
        s."purchases",
        s."left_in_cart"
FROM    stats       s
LEFT  JOIN page_meta m ON s."product_id" = m."product_id"
ORDER BY s."product_id";