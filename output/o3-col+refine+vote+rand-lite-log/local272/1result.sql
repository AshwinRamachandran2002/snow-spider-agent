WITH req AS (                                                    -- quantity required per product
    SELECT "product_id",
           SUM("qty") AS "req_qty"
    FROM   "orderlines"
    WHERE  "order_id" = 423
    GROUP  BY "product_id"
),
inv AS (                                                    -- inventory of those products in warehouse-1
    SELECT i."id"            AS "inv_id",
           i."product_id",
           i."qty",
           p."purchased",
           l."aisle",
           l."position"
    FROM   "inventory"  AS i
    JOIN   "locations"  AS l ON l."id" = i."location_id"
    JOIN   "purchases"  AS p ON p."id" = i."purchase_id"
    WHERE  l."warehouse" = 1
      AND  i."product_id" IN (SELECT "product_id" FROM req)
),
ord AS (                                                   -- add running total per product
    SELECT inv.*,
           SUM(inv."qty") OVER (
               PARTITION BY inv."product_id"
               ORDER BY     inv."purchased", inv."qty"
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           )                       AS "cum_qty",
           req."req_qty"
    FROM   inv
    JOIN   req ON req."product_id" = inv."product_id"
),
pick AS (                                                  -- calculate exact pick quantity per location
    SELECT ord."product_id",
           ord."aisle",
           ord."position",
           CASE
               WHEN ord."cum_qty" - ord."qty" >= ord."req_qty" THEN 0              -- already satisfied
               WHEN ord."cum_qty"              <= ord."req_qty" THEN ord."qty"     -- take all
               ELSE  ord."req_qty" - (ord."cum_qty" - ord."qty")                   -- take partial
           END AS "pick_qty"
    FROM   ord
)
SELECT  "product_id",
        "aisle",
        "position",
        "pick_qty"
FROM    pick
WHERE   "pick_qty" > 0                                  -- only locations we actually need to visit
ORDER BY "product_id",
         "aisle",
         "position";