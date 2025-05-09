WITH RECURSIVE
    -- expand every packaging_id down to its leaf‑level items
    expanded(packaging_id, leaf_id, qty) AS (
        /* start with the direct children */
        SELECT
            pr.packaging_id,
            pr.contains_id,
            1.0 * pr.qty                -- cast to REAL to keep decimals
        FROM packaging_relations pr

        UNION ALL

        /* dive deeper whenever the current leaf is itself a package */
        SELECT
            e.packaging_id,
            pr.contains_id,
            e.qty * pr.qty              -- multiply quantities along the path
        FROM expanded e
        JOIN packaging_relations pr
          ON pr.packaging_id = e.leaf_id
    ),

    -- keep only the true leaves (those that are never a packaging_id)
    leaf_totals AS (
        SELECT
            packaging_id,
            SUM(qty) AS total_qty
        FROM expanded
        WHERE leaf_id NOT IN (SELECT DISTINCT packaging_id FROM packaging_relations)
        GROUP BY packaging_id
    )

/* average of the total quantities across all final packaging combinations */
SELECT
    AVG(total_qty) AS avg_total_leaf_qty
FROM leaf_totals;