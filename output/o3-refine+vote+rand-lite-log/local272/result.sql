WITH
/* 1. quantity that has to be shipped for each product in order 423          */
order_demand AS (
    SELECT product_id,
           SUM(qty) AS demand_qty
    FROM   orderlines
    WHERE  order_id = 423
    GROUP  BY product_id
),
/* 2. all inventory that can be used (warehouse = 1) ordered
      by    • oldest purchase date first
      and   • smaller on‑hand quantity next                                      */
inv_prioritised AS (
    SELECT  i.product_id,
            l.aisle,
            l.position,
            i.qty          AS loc_qty,
            p.purchased    AS purchased_date,
            /* running total inside the ordered set for the product            */
            SUM(i.qty) OVER (PARTITION BY i.product_id
                            ORDER BY p.purchased, i.qty, i.id) AS cum_qty
    FROM    inventory   i
    JOIN    locations   l ON l.id = i.location_id
    JOIN    purchases   p ON p.id = i.purchase_id
    WHERE   l.warehouse = 1
      AND   i.product_id IN (SELECT product_id FROM order_demand)
),
/* 3. decide how much to pick from each location                               */
alloc AS (
    SELECT  ip.product_id,
            ip.aisle,
            ip.position,
            ip.purchased_date,
            CASE
                 /* demand already satisfied before this location */
                 WHEN ip.cum_qty - ip.loc_qty >= od.demand_qty THEN 0
                 /* we still need everything on the location      */
                 WHEN ip.cum_qty <= od.demand_qty               THEN ip.loc_qty
                 /* only part of the location is needed           */
                 ELSE od.demand_qty - (ip.cum_qty - ip.loc_qty)
            END AS pick_qty
    FROM    inv_prioritised ip
    JOIN    order_demand    od USING (product_id)
)
/* 4. result: where and how much to pick                                        */
SELECT  product_id,
        aisle,
        position,
        pick_qty
FROM    alloc
WHERE   pick_qty > 0          -- ignore locations that are not touched
ORDER BY product_id,
         purchased_date,
         aisle,
         position;