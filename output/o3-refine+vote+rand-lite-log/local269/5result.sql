WITH RECURSIVE
/* 1. Packages that are NOT themselves contained in any other
      package ⇒ “final” top‑level combinations                     */
root_pack AS (
    SELECT DISTINCT pr.packaging_id
    FROM   packaging_relations pr
    LEFT   JOIN packaging_relations pr2
           ON pr.packaging_id = pr2.contains_id
    WHERE  pr2.packaging_id IS NULL
),

/* 2. Expand every root package down through all nested levels,
      multiplying the quantities on the way                      */
hierarchy(packaging_id, leaf_id, qty_mult) AS (
    /* direct children of the root package */
    SELECT pr.packaging_id,
           pr.contains_id,
           CAST(pr.qty AS REAL)          -- start multiplier
    FROM   packaging_relations pr
    JOIN   root_pack rp
           ON rp.packaging_id = pr.packaging_id

    UNION ALL

    /* keep going as long as the current child itself
       contains something further                                   */
    SELECT h.packaging_id,
           pr.contains_id,
           h.qty_mult * pr.qty
    FROM   hierarchy h
    JOIN   packaging_relations pr
           ON h.leaf_id = pr.packaging_id
),

/* 3. Keep only the true leaf items (those that do not act as
      a container for anything else)                              */
leaf_rows AS (
    SELECT h.packaging_id,
           h.leaf_id,
           h.qty_mult
    FROM   hierarchy h
    LEFT   JOIN packaging_relations pr
           ON h.leaf_id = pr.packaging_id
    WHERE  pr.packaging_id IS NULL
),

/* 4. Total quantity of all leaf items for every top‑level package */
totals AS (
    SELECT packaging_id,
           SUM(qty_mult) AS total_qty
    FROM   leaf_rows
    GROUP BY packaging_id
)

/* 5. Average of those totals                                     */
SELECT AVG(total_qty) AS avg_total_leaf_qty
FROM   totals;