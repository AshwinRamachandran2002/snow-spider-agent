WITH RECURSIVE
/* 1. “Final” (stand‑alone) packaging combinations ­– those that are never
      themselves contained inside another package                         */
roots AS (
    SELECT DISTINCT packaging_id AS root_id
    FROM packaging_relations
    WHERE packaging_id NOT IN (SELECT contains_id FROM packaging_relations)
),

/* 2. Expand each root package down to all leaf‑level items, multiplying
      the quantities through every level of nesting                      */
rec(root_id, item_id, qty_mult) AS (
    -- direct children of each root
    SELECT r.root_id,
           pr.contains_id,
           pr.qty
    FROM roots r
    JOIN packaging_relations pr
      ON pr.packaging_id = r.root_id

    UNION ALL

    -- deeper levels
    SELECT rec.root_id,
           pr.contains_id,
           rec.qty_mult * pr.qty
    FROM rec
    JOIN packaging_relations pr
      ON pr.packaging_id = rec.item_id
),

/* 3. Total quantity of leaf items for each root package                 */
leaf_totals AS (
    SELECT root_id,
           SUM(qty_mult) AS total_qty
    FROM rec
    WHERE item_id NOT IN (SELECT DISTINCT packaging_id FROM packaging_relations)
    GROUP BY root_id
)

/* 4. Average of those totals                                            */
SELECT AVG(total_qty) AS average_total_quantity
FROM leaf_totals;