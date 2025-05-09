WITH product_pages AS (
    -- keep only genuine product pages
    SELECT DISTINCT 
           "page_id",
           "product_id",
           "page_name"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_PAGE_HIERARCHY"
    WHERE "page_id" NOT IN (1,2,12,13)
),

/* -----------------------------
   1. Total PAGE VIEWS per product
--------------------------------*/
views AS (
    SELECT 
           pp."product_id",
           COUNT(*) AS "views"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS" e
    JOIN product_pages pp
         ON e."page_id" = pp."page_id"
    WHERE e."event_type" = 1        -- Page View
    GROUP BY pp."product_id"
),

/* -----------------------------
   2. All ADD-TO-CART actions
--------------------------------*/
add_events AS (
    SELECT 
           e."visit_id",
           pp."product_id"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS" e
    JOIN product_pages pp
         ON e."page_id" = pp."page_id"
    WHERE e."event_type" = 2        -- Add to Cart
),

adds AS (
    SELECT 
           "product_id",
           COUNT(*) AS add_to_cart
    FROM add_events
    GROUP BY "product_id"
),

/* -----------------------------
   3. Visits that completed ANY purchase
--------------------------------*/
purchase_visits AS (
    SELECT DISTINCT 
           "visit_id"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."SHOPPING_CART_EVENTS"
    WHERE "event_type" = 3          -- Purchase
),

/* -----------------------------
   4. ADD-TO-CARTs that belong to a PURCHASE visit
--------------------------------*/
purchases AS (
    SELECT 
           a."product_id",
           COUNT(*) AS purchases
    FROM add_events a
    JOIN purchase_visits p
         ON a."visit_id" = p."visit_id"
    GROUP BY a."product_id"
),

/* -----------------------------
   5. ADD-TO-CARTs left in cart (no purchase in that visit)
--------------------------------*/
left_cart AS (
    SELECT 
           a."product_id",
           COUNT(*) AS left_in_cart
    FROM add_events a
    LEFT JOIN purchase_visits p
           ON a."visit_id" = p."visit_id"
    WHERE p."visit_id" IS NULL      -- no purchase in that visit
    GROUP BY a."product_id"
)

/* -----------------------------
   6. Final aggregation
--------------------------------*/
SELECT
       pp."product_id",
       pp."page_name",
       COALESCE(v."views",0)        AS "views",
       COALESCE(ad.add_to_cart,0)   AS "add_to_cart",
       COALESCE(pu.purchases,0)     AS "purchases",
       COALESCE(l.left_in_cart,0)   AS "left_in_cart"
FROM product_pages pp
LEFT JOIN views      v  ON pp."product_id" = v."product_id"
LEFT JOIN adds       ad ON pp."product_id" = ad."product_id"
LEFT JOIN purchases  pu ON pp."product_id" = pu."product_id"
LEFT JOIN left_cart  l  ON pp."product_id" = l."product_id"
ORDER BY "views" DESC NULLS LAST;