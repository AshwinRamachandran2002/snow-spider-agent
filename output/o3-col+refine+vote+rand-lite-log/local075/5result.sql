/*  Breakdown of product-level activity  
    – page views, add-to-cart, purchases and items left in cart  
    – generic pages 1,2,12,13 are excluded for every metric           */

WITH product_list AS (          /* all real product pages             */
    SELECT DISTINCT h."product_id"
    FROM   "shopping_cart_page_hierarchy" h
    WHERE  h."page_id" NOT IN (1,2,12,13)
      AND  h."product_id" IS NOT NULL
),

views AS (                      /* page-view events (event_type = 1)  */
    SELECT h."product_id",
           COUNT(*) AS "views"
    FROM   "shopping_cart_events"         e
    JOIN   "shopping_cart_page_hierarchy" h
           ON e."page_id" = h."page_id"
    WHERE  e."event_type" = 1
      AND  e."page_id" NOT IN (1,2,12,13)
      AND  h."product_id" IS NOT NULL
    GROUP BY h."product_id"
),

adds AS (                       /* add-to-cart events (event_type = 2) */
    SELECT h."product_id",
           COUNT(*) AS "adds_to_cart"
    FROM   "shopping_cart_events"         e
    JOIN   "shopping_cart_page_hierarchy" h
           ON e."page_id" = h."page_id"
    WHERE  e."event_type" = 2
      AND  e."page_id" NOT IN (1,2,12,13)
      AND  h."product_id" IS NOT NULL
    GROUP BY h."product_id"
),

purch AS (                      /* purchase events (event_type = 3)    */
    SELECT h."product_id",
           COUNT(*) AS "purchases"
    FROM   "shopping_cart_events"         e
    JOIN   "shopping_cart_page_hierarchy" h
           ON e."page_id" = h."page_id"
    WHERE  e."event_type" = 3
      AND  e."page_id" NOT IN (1,2,12,13)
      AND  h."product_id" IS NOT NULL
    GROUP BY h."product_id"
)

SELECT
       pl."product_id",
       COALESCE(v."views",0)            AS "views",
       COALESCE(a."adds_to_cart",0)     AS "adds_to_cart",
       COALESCE(p."purchases",0)        AS "purchases",
       (COALESCE(a."adds_to_cart",0)
        - COALESCE(p."purchases",0))    AS "left_in_cart"
FROM   product_list  pl
LEFT  JOIN views  v ON pl."product_id" = v."product_id"
LEFT  JOIN adds   a ON pl."product_id" = a."product_id"
LEFT  JOIN purch  p ON pl."product_id" = p."product_id"
ORDER BY pl."product_id";