WITH ordered AS (          -- total ordered per product
    SELECT  "product_id",
            SUM("qty") AS ordered_qty
    FROM    "orderlines"
    GROUP BY "product_id"
),
/* rank every inventory row belonging to the same
   location & product by
        1) earliest purchase date (FIFO)
        2) then by the smallest on-hand quantity              */
ranked_inv AS (
    SELECT  i."id"              AS inv_id,
            i."location_id",
            i."product_id",
            i."qty",
            ROW_NUMBER() OVER (
                PARTITION BY i."location_id", i."product_id"
                ORDER BY     pu."purchased",
                             i."qty"
            ) AS rn
    FROM    "inventory"  i
    JOIN    "purchases"  pu
           ON pu."id" = i."purchase_id"
),
/* keep only the earliest/smallest inventory row
   for every (location, product)                              */
chosen_inv AS (
    SELECT  inv_id,
            location_id,
            product_id,
            qty
    FROM    ranked_inv
    WHERE   rn = 1
),
/* overlap between what the pick line asks for and what
   the chosen inventory row can actually supply               */
alloc AS (
    SELECT  pl."picklist_id",
            pl."line_no",
            pl."product_id",
            -- scalar MIN(x,y) (not an aggregate) gives the overlap
            MIN(pl."qty", ci."qty") AS alloc_qty
    FROM    "picking_line" pl
    JOIN    chosen_inv     ci
          ON ci."location_id" = pl."location_id"
         AND ci."product_id"  = pl."product_id"
),
picked AS (                -- total “really” picked per product
    SELECT  "product_id",
            SUM(alloc_qty) AS picked_qty
    FROM    alloc
    GROUP BY "product_id"
),
percentages AS (           -- pick % per product
    SELECT  pr."name"                            AS product_name,
            (CAST(p.picked_qty AS REAL) /
             NULLIF(o.ordered_qty,0))            AS pick_ratio
    FROM    ordered    o
    JOIN    picked     p   ON p."product_id" = o."product_id"
    JOIN    "products" pr  ON pr."id"        = o."product_id"
)
SELECT  product_name,
        ROUND(pick_ratio * 100, 4) AS avg_pick_percentage
FROM    percentages
ORDER BY product_name;