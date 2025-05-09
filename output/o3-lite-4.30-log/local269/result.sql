WITH RECURSIVE
    top_packages AS (
        SELECT DISTINCT packaging_id
        FROM packaging_relations
        WHERE packaging_id NOT IN (
              SELECT DISTINCT contains_id FROM packaging_relations
        )
    ),
    tree(pkg_root, leaf_id, qty_factor) AS (
        SELECT pr.packaging_id, pr.contains_id, pr.qty
        FROM   packaging_relations pr
        JOIN   top_packages tp ON tp.packaging_id = pr.packaging_id
        UNION ALL
        SELECT t.pkg_root, pr.contains_id, t.qty_factor * pr.qty
        FROM   tree t
        JOIN   packaging_relations pr ON pr.packaging_id = t.leaf_id
    ),
    leaf_quantities AS (
        SELECT pkg_root, qty_factor AS leaf_qty
        FROM   tree
        WHERE  leaf_id NOT IN (SELECT DISTINCT packaging_id FROM packaging_relations)
    ),
    totals AS (
        SELECT pkg_root,
               SUM(leaf_qty) AS total_leaf_qty
        FROM   leaf_quantities
        GROUP BY pkg_root
    )
SELECT ROUND(AVG(total_leaf_qty),4) AS average_total_quantity
FROM   totals;