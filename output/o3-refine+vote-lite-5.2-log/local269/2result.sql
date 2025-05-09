WITH RECURSIVE
-- all parent packages we must expand
roots AS (
    SELECT DISTINCT "packaging_id" AS root_id
    FROM "packaging_relations"
),
-- recursively walk down every packaging → contained item path,
-- multiplying the quantities along the way
expanded AS (
    -- level‑0 (direct children of each root package)
    SELECT
        pr."packaging_id"      AS root_id,
        pr."contains_id"       AS item_id,
        pr."qty"               AS qty_mult
    FROM "packaging_relations" pr

    UNION ALL

    -- deeper levels: keep multiplying the quantities
    SELECT
        e.root_id,
        pr2."contains_id",
        e.qty_mult * pr2."qty"
    FROM expanded e
    JOIN "packaging_relations" pr2
         ON pr2."packaging_id" = e.item_id
),
-- keep only the leaf‑level items (those that do not themselves have children)
leaf_items AS (
    SELECT
        e.root_id,
        e.qty_mult
    FROM expanded e
    LEFT JOIN "packaging_relations" pr
           ON pr."packaging_id" = e.item_id
    WHERE pr."packaging_id" IS NULL        -- indicates a leaf item
),
-- total quantity of leaf items per root package
package_totals AS (
    SELECT
        root_id,
        SUM(qty_mult) AS total_leaf_qty
    FROM leaf_items
    GROUP BY root_id
)
-- average of those totals across all packages
SELECT
    AVG(total_leaf_qty) AS avg_total_leaf_quantity
FROM package_totals;