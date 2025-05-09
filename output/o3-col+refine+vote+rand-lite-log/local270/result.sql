WITH RECURSIVE
-- 1. Top-level packages = those that never appear as a child
top_pkg AS (
    SELECT id   AS top_id,
           name AS top_name
    FROM   packaging
    WHERE  id NOT IN (SELECT contains_id FROM packaging_relations)
),

-- 2. Recursively walk the hierarchy, multiplying quantities on the way down
exploded AS (
    -- level-0 : direct children of every top-level package
    SELECT t.top_id,
           pr.contains_id AS item_id,
           pr.qty         AS eff_qty
    FROM   top_pkg            AS t
    JOIN   packaging_relations AS pr
           ON pr.packaging_id = t.top_id

    UNION ALL

    -- deeper levels : follow relations further
    SELECT e.top_id,
           pr.contains_id                         AS item_id,
           e.eff_qty * pr.qty                     AS eff_qty
    FROM   exploded            AS e
    JOIN   packaging_relations AS pr
           ON pr.packaging_id = e.item_id
)

-- 3. Aggregate total effective quantity per (top package, contained item)
SELECT  p_top.name  AS top_level_container,
        p_item.name AS contained_item,
        SUM(e.eff_qty) AS total_quantity
FROM    exploded      AS e
JOIN    packaging     AS p_top
        ON p_top.id = e.top_id
JOIN    packaging     AS p_item
        ON p_item.id = e.item_id
GROUP BY e.top_id, e.item_id
HAVING  SUM(e.eff_qty) > 500
ORDER BY p_top.name, p_item.name;