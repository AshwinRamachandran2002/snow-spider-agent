WITH RECURSIVE
/* 1.  Top‑level containers = never themselves contained in another package */
top_containers AS (
    SELECT id  AS top_id,
           name AS top_name
    FROM   packaging
    WHERE  id NOT IN (SELECT contains_id FROM packaging_relations)
),

/* 2.  Walk the hierarchy, multiplying the quantities on the way down   */
recursion AS (
    /* anchor – immediate children of a top‑level container */
    SELECT  tc.top_id,
            tc.top_name,
            pr.contains_id       AS child_id,
            pr.qty               AS qty_accum
    FROM    top_containers tc
    JOIN    packaging_relations pr
           ON pr.packaging_id = tc.top_id

    UNION ALL

    /* recursive step – keep going while the child is itself a container */
    SELECT  r.top_id,
            r.top_name,
            pr.contains_id,
            r.qty_accum * pr.qty
    FROM    recursion r
    JOIN    packaging_relations pr
           ON pr.packaging_id = r.child_id
),

/* 3.  Keep only the leaf items (those that contain nothing further)   */
leaf_items AS (
    SELECT  top_id,
            top_name,
            child_id  AS item_id,
            qty_accum
    FROM    recursion
    WHERE   child_id NOT IN (SELECT packaging_id FROM packaging_relations)
),

/* 4.  Add up quantities of each item reached through all possible paths */
item_totals AS (
    SELECT  top_id,
            top_name,
            item_id,
            SUM(qty_accum) AS total_qty
    FROM    leaf_items
    GROUP BY top_id, top_name, item_id
)

/* 5.  Return only those (container, item) pairs whose total exceeds 500 */
SELECT  tc.top_name  AS container_name,
        p.name       AS item_name
FROM    item_totals it
JOIN    packaging p   ON p.id  = it.item_id
JOIN    top_containers tc ON tc.top_id = it.top_id
WHERE   it.total_qty > 500
ORDER BY container_name,
         item_name;