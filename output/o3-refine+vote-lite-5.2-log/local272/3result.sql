WITH
/* 1.  All order lines that belong to order 423                         */
order_needs AS (
    SELECT
        ol.id                    AS orderline_id,
        ol.product_id,
        ol.qty                   AS need_qty,
        /* cumulative quantity already needed up‑to and incl. this line */
        SUM(ol.qty) OVER (
            PARTITION BY ol.product_id
            ORDER BY ol.id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)          AS cum_need_curr
    FROM orderlines AS ol
    WHERE ol.order_id = 423
),
order_needs_ranged AS (
    SELECT
        orderline_id,
        product_id,
        need_qty,
        cum_need_curr,
        /* quantity needed before this line starts (previous cum value) */
        cum_need_curr - need_qty                                       AS cum_need_prev
    FROM order_needs
),

/* 2.  Inventory that is in warehouse 1, sorted by
       (a) oldest purchase first, (b) the smaller pallet/box first      */
inv AS (
    SELECT
        i.id                     AS inv_id,
        i.product_id,
        i.qty                    AS avail_qty,
        l.aisle,
        l.position,
        p.purchased              AS purchased_date,
        /* cumulative stock after taking this location into account     */
        SUM(i.qty) OVER (
            PARTITION BY i.product_id
            ORDER BY p.purchased, i.qty, i.id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)          AS cum_inv_curr
    FROM inventory  AS i
    JOIN locations  AS l  ON l.id = i.location_id
                         AND l.warehouse = 1          -- only warehouse 1
    LEFT JOIN purchases AS p ON p.id = i.purchase_id   -- gives purchase date
),
inv_ranged AS (
    SELECT
        inv_id,
        product_id,
        avail_qty,
        aisle,
        position,
        purchased_date,
        cum_inv_curr,
        cum_inv_curr - avail_qty                                  AS cum_inv_prev
    FROM inv
)

/* 3.  Intersect the needed‑ranges with the inventory‑ranges
       (idea: treat both as number lines and find overlaps)            */
SELECT
    n.orderline_id,
    n.product_id,
    i.aisle,
    i.position,
    /* overlap length = qty to pick from this location for this line   */
    (MIN(i.cum_inv_curr , n.cum_need_curr) -
     MAX(i.cum_inv_prev , n.cum_need_prev)) AS qty_to_pick
FROM order_needs_ranged AS n
JOIN inv_ranged        AS i
      ON i.product_id = n.product_id
     /* ranges overlap if the start of one is before the end of the
        other and vice‑versa                                           */
     AND i.cum_inv_curr  > n.cum_need_prev
     AND i.cum_inv_prev  < n.cum_need_curr
/* keep only positive overlaps                                         */
WHERE (MIN(i.cum_inv_curr , n.cum_need_curr) -
       MAX(i.cum_inv_prev , n.cum_need_prev)) > 0
ORDER BY
      n.orderline_id,               -- keep picking sequence of lines
      i.purchased_date,             -- oldest stock first
      i.avail_qty,                  -- then the smaller lots
      i.inv_id;