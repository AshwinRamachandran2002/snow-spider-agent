WITH product_events AS (
    SELECT
        e.page_id,
        ph.page_name,
        ph.product_category,
        ph.product_id,
        -- how many times the product page was viewed
        SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
        -- how many times the product was added to the cart
        SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart,
        -- how many times the product was actually purchased
        SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases
    FROM shopping_cart_events            AS e
    JOIN shopping_cart_page_hierarchy    AS ph
          ON e.page_id = ph.page_id
    -- remove non‑product pages
    WHERE e.page_id NOT IN (1, 2, 12, 13)
    GROUP BY e.page_id
)
SELECT
    page_id,
    page_name,
    product_category,
    product_id,
    views,
    add_to_cart,
    purchases,
    /* number left in cart = added – purchased, never negative */
    CASE 
        WHEN add_to_cart > purchases THEN add_to_cart - purchases
        ELSE 0
    END AS left_in_cart
FROM product_events
ORDER BY page_id;