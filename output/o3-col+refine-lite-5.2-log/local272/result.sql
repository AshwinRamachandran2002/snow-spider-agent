WITH
/* 1. Total quantity of every product that must be supplied for Order 423 */
order_need AS (
    SELECT  "product_id",
            SUM("qty") AS "need_qty"
    FROM    "orderlines"
    WHERE   "order_id" = 423
    GROUP BY "product_id"
),

/* 2. All inventory in Warehouse 1 for those products,
      sorted by picking priority: oldest purchase first,
      then the smallest on‑hand quantity                                   */
prio_inv AS (
    SELECT  i."product_id",
            i."id"            AS "inventory_id",
            i."qty"           AS "inv_qty",
            p."purchased",
            l."aisle",
            l."position",
            SUM(i."qty") OVER (PARTITION BY i."product_id"
                               ORDER BY p."purchased", i."qty")
                               AS "cum_inv_qty"
    FROM    "inventory"   i
    JOIN    "purchases"   p ON p."id" = i."purchase_id"
    JOIN    "locations"   l ON l."id" = i."location_id"
    WHERE   l."warehouse" = 1
      AND   i."product_id" IN (SELECT "product_id" FROM order_need)
),

/* 3. Decide how many units to pick from each inventory line
      so that the required total is met but never exceeded                 */
calc AS (
    SELECT  prio_inv."product_id",
            prio_inv."aisle",
            prio_inv."position",
            CASE
              WHEN prio_inv."cum_inv_qty" - prio_inv."inv_qty" >= order_need."need_qty" THEN 0
              WHEN prio_inv."cum_inv_qty"                         >  order_need."need_qty" THEN
                   order_need."need_qty" - (prio_inv."cum_inv_qty" - prio_inv."inv_qty")
              ELSE prio_inv."inv_qty"
            END  AS "pick_qty"
    FROM    prio_inv
    JOIN    order_need
          ON order_need."product_id" = prio_inv."product_id"
)

/* 4. Final pick list – only lines with a positive pick quantity           */
SELECT  "product_id",
        "aisle",
        "position",
        "pick_qty"
FROM    calc
WHERE   "pick_qty" > 0
ORDER BY "product_id",
         "aisle",
         "position";