WITH RECURSIVE
/* 1. top‑level containers – they never appear as something *inside* another package */
top_containers AS (
    SELECT DISTINCT pr.packaging_id
    FROM   packaging_relations pr
    WHERE  pr.packaging_id NOT IN (SELECT contains_id FROM packaging_relations)
),

/* 2. walk the hierarchy, multiplying the quantities on the way down               */
hierarchy(container_id, item_id, total_qty) AS (
    /* direct children of the top‑level container */
    SELECT tc.packaging_id,
           pr.contains_id,
           pr.qty
    FROM   top_containers tc
    JOIN   packaging_relations pr
           ON pr.packaging_id = tc.packaging_id

    UNION ALL
    /* recurse through any nested packages */
    SELECT h.container_id,
           pr.contains_id,
           h.total_qty * pr.qty          -- accumulate quantity multiplicatively
    FROM   hierarchy h
    JOIN   packaging_relations pr
           ON pr.packaging_id = h.item_id
),

/* 3. aggregate the total quantity per (container , item) pair */
totals AS (
    SELECT container_id,
           item_id,
           SUM(total_qty) AS total_qty
    FROM   hierarchy
    GROUP  BY container_id, item_id
    HAVING SUM(total_qty) > 500          -- keep only items that exceed 500 units
)

/* 4. return container and item names whose accumulated qty > 500 */
SELECT pc.name AS container_name,
       pi.name AS item_name
FROM   totals t
JOIN   packaging pc ON pc.id = t.container_id
JOIN   packaging pi ON pi.id = t.item_id
ORDER  BY pc.name, pi.name;