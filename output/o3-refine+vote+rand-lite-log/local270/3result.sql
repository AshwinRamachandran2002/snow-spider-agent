WITH RECURSIVE
/* 1.  Top‑level containers = a packaging_id that is never itself a contains_id */
top_containers(id, name) AS (
    SELECT pr.packaging_id,
           p.name
    FROM   packaging_relations pr
    LEFT JOIN packaging p ON p.id = pr.packaging_id
    WHERE  pr.packaging_id NOT IN (SELECT contains_id FROM packaging_relations)
    GROUP BY pr.packaging_id
),

/* 2.  Walk the hierarchy, multiplying the quantities along the path */
rec(container_id, container_name, item_id, item_name, total_qty) AS (
    /* direct children of the top‑level container */
    SELECT tc.id,
           tc.name,
           pr.contains_id,
           p2.name,
           pr.qty
    FROM   top_containers      tc
    JOIN   packaging_relations pr ON pr.packaging_id = tc.id
    LEFT JOIN packaging        p2 ON p2.id = pr.contains_id
    
    UNION ALL
    
    /* deeper levels: multiply quantities down the path */
    SELECT r.container_id,
           r.container_name,
           pr.contains_id,
           p2.name,
           r.total_qty * pr.qty
    FROM   rec                 r
    JOIN   packaging_relations pr ON pr.packaging_id = r.item_id
    LEFT JOIN packaging        p2 ON p2.id = pr.contains_id
),

/* 3.  Sum quantities for each (container,item) pair – there might be several paths */
agg AS (
    SELECT container_id,
           container_name,
           item_id,
           item_name,
           SUM(total_qty) AS total_qty
    FROM   rec
    GROUP BY container_id, container_name, item_id, item_name
)

/* 4.  Return the containers that have at least one item whose quantity > 500 */
SELECT DISTINCT
       container_name AS top_level_container,
       item_name      AS contained_item
FROM   agg
WHERE  total_qty > 500
ORDER BY top_level_container,
         contained_item;