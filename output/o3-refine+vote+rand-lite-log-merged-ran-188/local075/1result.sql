WITH filtered_events AS (
    SELECT  e."visit_id",
            e."event_type",
            ph."product_id"
    FROM    "shopping_cart_events"        AS e
    JOIN    "shopping_cart_page_hierarchy" ph
                ON ph."page_id" = e."page_id"
    WHERE   e."page_id" NOT IN (1,2,12,13)           -- drop the generic pages
),

/* 1) page-view counts */
views AS (
    SELECT  "product_id",
            COUNT(*) AS view_count
    FROM    filtered_events
    WHERE   "event_type" = 1                         -- Page View
    GROUP BY "product_id"
),

/* 2) add-to-cart counts */
add_cart AS (
    SELECT  "product_id",
            COUNT(*) AS add_to_cart_count
    FROM    filtered_events
    WHERE   "event_type" = 2                         -- Add to Cart
    GROUP BY "product_id"
),

/* 3) purchase counts */
purchases AS (
    SELECT  "product_id",
            COUNT(*) AS purchase_count
    FROM    filtered_events
    WHERE   "event_type" = 3                         -- Purchase
    GROUP BY "product_id"
),

/* 4) visits that recorded ANY purchase (of any product) */
purchase_visits AS (
    SELECT DISTINCT "visit_id"
    FROM   filtered_events
    WHERE  "event_type" = 3
),

/* 5) left-in-cart: visits that added a product but never purchased anything */
left_in_cart AS (
    SELECT  ac."product_id",
            COUNT(*) AS left_in_cart_count
    FROM   (SELECT DISTINCT "visit_id", "product_id"
            FROM   filtered_events
            WHERE  "event_type" = 2)  AS ac          -- unique Add-to-Cart per visit/product
    LEFT JOIN purchase_visits  pv
           ON pv."visit_id" = ac."visit_id"
    WHERE   pv."visit_id" IS NULL                    -- visit had no purchase
    GROUP BY ac."product_id"
),

/* 6) list of all products seen in the filtered events */
all_products AS (
    SELECT DISTINCT "product_id"
    FROM   filtered_events
)

SELECT  ap."product_id",
        COALESCE(v.view_count,0)              AS view_count,
        COALESCE(a.add_to_cart_count,0)       AS add_to_cart_count,
        COALESCE(l.left_in_cart_count,0)      AS left_in_cart_count,
        COALESCE(p.purchase_count,0)          AS purchase_count
FROM    all_products      AS ap
LEFT JOIN views           AS v  ON v."product_id" = ap."product_id"
LEFT JOIN add_cart        AS a  ON a."product_id" = ap."product_id"
LEFT JOIN left_in_cart    AS l  ON l."product_id" = ap."product_id"
LEFT JOIN purchases       AS p  ON p."product_id" = ap."product_id"
ORDER BY ap."product_id";