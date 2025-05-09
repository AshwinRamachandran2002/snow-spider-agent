WITH RECURSIVE hierarchy(parent_id, item_id, qty_mult) AS (
    -- direct links
    SELECT  packaging_id,
            contains_id,
            qty
    FROM    packaging_relations
    
    UNION ALL
    
    -- climb up the chain, multiplying quantities on the way
    SELECT  pr.packaging_id,
            h.item_id,
            pr.qty * h.qty_mult
    FROM    hierarchy h
    JOIN    packaging_relations pr
           ON pr.contains_id = h.parent_id
),
-- containers that are never themselves contained – i.e. “top level”
top_level AS (
    SELECT DISTINCT pr.packaging_id
    FROM   packaging_relations pr
    LEFT   JOIN packaging_relations ch
           ON ch.contains_id = pr.packaging_id
    WHERE  ch.packaging_id IS NULL
),
-- total quantity of every (top‑level, leaf‑item) pair
totals AS (
    SELECT  h.parent_id,
            h.item_id,
            SUM(h.qty_mult) AS total_qty
    FROM    hierarchy h
    JOIN    top_level t
           ON t.packaging_id = h.parent_id
    GROUP BY h.parent_id, h.item_id
    HAVING  total_qty > 500        -- only pairs exceeding 500
)
SELECT  tp.name AS top_container_name,
        it.name AS item_name,
        totals.total_qty
FROM    totals
JOIN    packaging tp ON tp.id = totals.parent_id
JOIN    packaging it ON it.id = totals.item_id
ORDER BY tp.name,
         it.name;