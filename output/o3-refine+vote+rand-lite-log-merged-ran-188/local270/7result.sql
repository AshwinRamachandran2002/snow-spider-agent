WITH RECURSIVE
-- 1.  top‑level containers = packages that are never themselves contained
top_containers AS (
    SELECT  p.id   AS container_id,
            p.name AS container_name
    FROM    packaging p
    WHERE   p.id NOT IN (SELECT contains_id FROM packaging_relations)
),

-- 2.  Walk the hierarchy, multiplying the quantities down the path
pkg_tree AS (
    /* first level under each top‑level container */
    SELECT  tc.container_id,
            tc.container_name,
            pr.contains_id        AS item_id,
            pi.name               AS item_name,
            pr.qty                AS qty_acc          -- quantity so far
    FROM    top_containers   tc
    JOIN    packaging_relations pr ON pr.packaging_id = tc.container_id
    JOIN    packaging          pi ON pi.id = pr.contains_id

    UNION ALL

    /* deeper levels */
    SELECT  pt.container_id,
            pt.container_name,
            pr.contains_id        AS item_id,
            pi.name               AS item_name,
            pt.qty_acc * pr.qty   AS qty_acc
    FROM    pkg_tree           pt
    JOIN    packaging_relations pr ON pr.packaging_id = pt.item_id
    JOIN    packaging          pi ON pi.id = pr.contains_id
)

-- 3.  add up all paths leading to the same container / item pair
SELECT      container_name,
            item_name
FROM       (SELECT  container_id,
                    container_name,
                    item_id,
                    item_name,
                    SUM(qty_acc) AS total_qty
            FROM    pkg_tree
            GROUP BY container_id, container_name, item_id, item_name)
WHERE       total_qty > 500
ORDER BY    container_name,
            item_name;