-- Breakdown per product: views, add-to-carts, purchases and items left in cart
SELECT
        ph."product_id",
        SUM(CASE WHEN ev."event_type" = 1 THEN 1 ELSE 0 END)                           AS "view_count",
        SUM(CASE WHEN ev."event_type" = 2 THEN 1 ELSE 0 END)                           AS "add_to_cart_count",
        SUM(CASE WHEN ev."event_type" = 3 THEN 1 ELSE 0 END)                           AS "purchase_count",
        SUM(CASE WHEN ev."event_type" = 2 THEN 1 ELSE 0 END) -
        SUM(CASE WHEN ev."event_type" = 3 THEN 1 ELSE 0 END)                           AS "left_in_cart"
FROM   "shopping_cart_events"          ev
JOIN   "shopping_cart_page_hierarchy"  ph
       ON ev."page_id" = ph."page_id"
WHERE  ev."page_id" NOT IN (1, 2, 12, 13)          -- exclude unwanted page IDs
GROUP  BY ph."product_id"
ORDER  BY ph."product_id";