WITH page_events AS (                -- all product-page events to consider
    SELECT e.visit_id,
           ph.product_id,
           e.event_type
    FROM   shopping_cart_events         AS e
    JOIN   shopping_cart_page_hierarchy AS ph
           ON e.page_id = ph.page_id
    WHERE  ph.product_id IS NOT NULL
      AND  e.page_id NOT IN (1,2,12,13)   -- exclude non-product pages
),
views AS (                              -- how many page views
    SELECT product_id,
           COUNT(*) AS views
    FROM   page_events
    WHERE  event_type = 1               -- Page View
    GROUP BY product_id
),
adds AS (                               -- how many add-to-cart clicks
    SELECT product_id,
           COUNT(*) AS added_to_cart
    FROM   page_events
    WHERE  event_type = 2               -- Add to Cart
    GROUP BY product_id
),
add_visits AS (                         -- visits in which product was added
    SELECT DISTINCT visit_id,
                    product_id
    FROM   page_events
    WHERE  event_type = 2
),
purchase_visits AS (                    -- those visits that ended in purchase
    SELECT DISTINCT av.product_id,
                    av.visit_id
    FROM   add_visits              AS av
    JOIN   shopping_cart_events    AS e
           ON e.visit_id = av.visit_id
    WHERE  e.event_type = 3             -- Purchase
),
purchases AS (                          -- purchase counts per product
    SELECT product_id,
           COUNT(*) AS purchases
    FROM   purchase_visits
    GROUP BY product_id
),
left_cart AS (                          -- adds with NO subsequent purchase
    SELECT av.product_id,
           COUNT(*) AS left_in_cart_no_purchase
    FROM   add_visits  AS av
    LEFT  JOIN purchase_visits AS pv
           ON  pv.product_id = av.product_id
          AND pv.visit_id   = av.visit_id
    WHERE  pv.visit_id IS NULL
    GROUP BY av.product_id
)
SELECT ph.product_id,
       COALESCE(v.views,0)                    AS views,
       COALESCE(a.added_to_cart,0)            AS added_to_cart,
       COALESCE(l.left_in_cart_no_purchase,0) AS left_in_cart_no_purchase,
       COALESCE(p.purchases,0)                AS purchases
FROM   shopping_cart_page_hierarchy AS ph
LEFT   JOIN views      AS v ON v.product_id = ph.product_id
LEFT   JOIN adds       AS a ON a.product_id = ph.product_id
LEFT   JOIN left_cart  AS l ON l.product_id = ph.product_id
LEFT   JOIN purchases  AS p ON p.product_id = ph.product_id
WHERE  ph.product_id IS NOT NULL
  AND  ph.page_id NOT IN (1,2,12,13)          -- final exclusion of pages
GROUP BY ph.product_id
ORDER BY ph.product_id;