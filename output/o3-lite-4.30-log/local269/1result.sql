WITH RECURSIVE pkg_tree(root_pkg_id, contains_id, qty) AS (
    -- first level relationships
    SELECT packaging_id, contains_id, qty
    FROM   packaging_relations
    UNION ALL
    -- expand while the component is itself a parent
    SELECT pt.root_pkg_id,
           pr.contains_id,
           pt.qty * pr.qty
    FROM   pkg_tree           AS pt
    JOIN   packaging_relations pr
           ON pt.contains_id = pr.packaging_id
),
leaf_rows AS (
    -- keep only components that never act as a parent (leaf items)
    SELECT pt.*
    FROM   pkg_tree pt
    LEFT JOIN packaging_relations pr2
           ON pt.contains_id = pr2.packaging_id
    WHERE  pr2.packaging_id IS NULL
),
leaf_totals AS (
    -- total leaf quantity inside each top‑level package
    SELECT root_pkg_id,
           SUM(qty) AS total_leaf_qty
    FROM   leaf_rows
    GROUP  BY root_pkg_id
),
top_level_totals AS (
    -- consider only packages that are NOT themselves components of another package
    SELECT lt.total_leaf_qty
    FROM   leaf_totals lt
    LEFT JOIN packaging_relations pr
           ON lt.root_pkg_id = pr.contains_id
    WHERE  pr.packaging_id IS NULL
)
SELECT ROUND(AVG(total_leaf_qty), 4) AS average_total_quantity
FROM   top_level_totals;