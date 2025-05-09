/*  FINAL PICK-LIST FOR ORDER 423
    – exactly the quantities required, taken from warehouse 1 only
    – priority : (1) oldest purchase_date  (2) smallest inventory-lot quantity
    – keeps the original order-line sequence                       */

WITH
/* every order-line that must be filled */
need AS (
    SELECT  ol.id        AS orderline_id,
            ol.product_id,
            ol.qty       AS qty_needed
    FROM    orderlines ol
    WHERE   ol.order_id = 423
),
/* every inventory lot in warehouse-1 for the products above
   plus its purchase-date & physical location                      */
inv AS (
    SELECT  i.id         AS inv_id,
            i.product_id,
            i.qty        AS inv_qty,
            p.purchased  AS purch_date,
            l.aisle,
            l.position
    FROM    inventory  i
    JOIN    purchases  p ON p.id = i.purchase_id
    JOIN    locations  l ON l.id = i.location_id
    WHERE   l.warehouse = 1
),
/* combine each order-line with all matching inventory lots,
   ordered by the picking priority                                */
x AS (
    SELECT  n.orderline_id,
            n.product_id,
            n.qty_needed,
            v.inv_id,
            v.inv_qty,
            v.purch_date,
            v.aisle,
            v.position,

            /* cumulated quantity BEFORE this lot */
            SUM(v.inv_qty) OVER (
                PARTITION BY n.orderline_id
                ORDER BY v.purch_date,
                         v.inv_qty,
                         v.inv_id
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ) AS cum_before,

            /* cumulated quantity INCLUDING this lot */
            SUM(v.inv_qty) OVER (
                PARTITION BY n.orderline_id
                ORDER BY v.purch_date,
                         v.inv_qty,
                         v.inv_id
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS cum_after
    FROM    need n
    JOIN    inv  v ON v.product_id = n.product_id
)
/* decide how much to take from EACH lot                           */
SELECT  orderline_id,
        product_id,
        aisle,
        position,
        CASE
            WHEN cum_before >= qty_needed            THEN 0               -- already satisfied
            WHEN cum_after  <= qty_needed            THEN inv_qty         -- take it all
            ELSE qty_needed - cum_before             END AS qty_to_pick
FROM    x
WHERE   qty_to_pick > 0                                                -- ignore zero picks
ORDER BY orderline_id,
         purch_date,
         inv_qty,
         inv_id;