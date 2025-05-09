WITH top_pkg AS (          -- all packages that are never themselves contained
    SELECT p.id, p.name
    FROM packaging p
    WHERE p.id IN  (SELECT packaging_id FROM packaging_relations)
      AND p.id NOT IN (SELECT contains_id  FROM packaging_relations)
),
rec (top_pkg_id, top_pkg_name, item_id, total_qty) AS (
    /* first-level contents of every top-level package */
    SELECT tp.id, tp.name,
           pr.contains_id,
           pr.qty
    FROM   top_pkg tp
    JOIN   packaging_relations pr
           ON pr.packaging_id = tp.id
    UNION ALL
    /* recurse further down the hierarchy */
    SELECT r.top_pkg_id, r.top_pkg_name,
           pr2.contains_id,
           r.total_qty * pr2.qty
    FROM   rec r
    JOIN   packaging_relations pr2
           ON pr2.packaging_id = r.item_id
)
SELECT   r.top_pkg_name  AS container,
         COALESCE(p.name, prod.name, r.item_id || '') AS item,
         SUM(r.total_qty) AS total_qty_in_container
FROM     rec r
LEFT JOIN packaging p ON p.id   = r.item_id        -- if the item is itself a package
LEFT JOIN products  prod ON prod.id = r.item_id    -- if the item is a product
GROUP BY container, item
HAVING   SUM(r.total_qty) > 500;