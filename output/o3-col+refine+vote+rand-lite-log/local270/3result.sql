WITH RECURSIVE pack_tree (top_id, item_id, total_qty) AS (
    -- Direct children
    SELECT  pr.packaging_id,
            pr.contains_id,
            pr.qty
    FROM    packaging_relations pr

    UNION ALL
    
    -- Walk further down
    SELECT  pt.top_id,
            pr.contains_id,
            pt.total_qty * pr.qty
    FROM    pack_tree           pt
    JOIN    packaging_relations pr
           ON pr.packaging_id = pt.item_id
),
-- Packages that are never contained inside another one
top_packages AS (
    SELECT id
    FROM   packaging
    WHERE  id NOT IN (SELECT contains_id FROM packaging_relations)
)
SELECT  p_top.name  AS container_name,
        p_item.name AS item_name,
        SUM(pt.total_qty) AS total_quantity
FROM    pack_tree      pt
JOIN    top_packages   tp     ON tp.id     = pt.top_id
JOIN    packaging      p_top  ON p_top.id  = pt.top_id
JOIN    packaging      p_item ON p_item.id = pt.item_id
GROUP BY p_top.name,
         p_item.name
HAVING   SUM(pt.total_qty) > 500;