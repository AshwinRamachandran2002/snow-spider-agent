WITH
-- 1. product page views (exclude non-product pages 1,2,12,13)
views AS (
    SELECT  p."product_id",
            COUNT(*) AS "page_views"
    FROM    "shopping_cart_events"         AS e
    JOIN    "shopping_cart_page_hierarchy" AS p
           ON e."page_id" = p."page_id"
    WHERE   e."event_type" = 1         -- Page View
      AND   e."page_id" NOT IN (1,2,12,13)
    GROUP BY p."product_id"
),

-- 2. add-to-cart actions (same page filter)
adds AS (
    SELECT  p."product_id",
            COUNT(*) AS "added_to_cart"
    FROM    "shopping_cart_events"         AS e
    JOIN    "shopping_cart_page_hierarchy" AS p
           ON e."page_id" = p."page_id"
    WHERE   e."event_type" = 2         -- Add to Cart
      AND   e."page_id" NOT IN (1,2,12,13)
    GROUP BY p."product_id"
),

-- 3. confirmed purchases (same page filter, insist on a valid product)
purchases AS (
    SELECT  p."product_id",
            COUNT(*) AS "purchases"
    FROM    "shopping_cart_events"         AS e
    JOIN    "shopping_cart_page_hierarchy" AS p
           ON e."page_id" = p."page_id"
    WHERE   e."event_type" = 3         -- Purchase
      AND   e."page_id" NOT IN (1,2,12,13)
      AND   p."product_id" IS NOT NULL
    GROUP BY p."product_id"
)

-- 4. combine the three metrics
SELECT  pid."product_id",
        COALESCE(v."page_views",0)            AS "page_views",
        COALESCE(a."added_to_cart",0)         AS "added_to_cart",
        COALESCE(a."added_to_cart",0) -
        COALESCE(pr."purchases",0)            AS "left_in_cart_without_purchase",
        COALESCE(pr."purchases",0)            AS "purchases"
FROM   (
        SELECT "product_id" FROM views
        UNION
        SELECT "product_id" FROM adds
        UNION
        SELECT "product_id" FROM purchases
       )                     AS pid
LEFT JOIN views      AS v  ON pid."product_id" = v."product_id"
LEFT JOIN adds       AS a  ON pid."product_id" = a."product_id"
LEFT JOIN purchases  AS pr ON pid."product_id" = pr."product_id"
ORDER BY pid."product_id";