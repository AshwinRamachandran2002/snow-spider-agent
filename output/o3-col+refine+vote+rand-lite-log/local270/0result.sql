WITH RECURSIVE
-- 1. Top-level containers (never themselves contained in another package)
top_containers AS (
    SELECT DISTINCT pr.packaging_id AS id
    FROM packaging_relations pr
    WHERE pr.packaging_id NOT IN (SELECT DISTINCT contains_id FROM packaging_relations)
),

-- 2. Walk the whole hierarchy, multiplying quantities down the branches
hierarchy AS (
    -- level 0 : direct children of every top-level container
    SELECT pr.packaging_id AS top_id,
           pr.contains_id  AS item_id,
           pr.qty          AS qty_mult
    FROM   packaging_relations pr
    JOIN   top_containers tc ON tc.id = pr.packaging_id

    UNION ALL
    -- level n : if the current item is itself a container, keep drilling down
    SELECT h.top_id,
           pr.contains_id,
           h.qty_mult * pr.qty
    FROM   hierarchy h
    JOIN   packaging_relations pr ON pr.packaging_id = h.item_id
)

-- 3. Summarise and keep only (container,item) pairs whose accumulated qty > 500
SELECT  p_top.name  AS container_name,
        p_item.name AS item_name,
        SUM(h.qty_mult) AS total_quantity
FROM    hierarchy h
JOIN    packaging p_top  ON p_top.id  = h.top_id
JOIN    packaging p_item ON p_item.id = h.item_id
GROUP BY p_top.name, p_item.name
HAVING  total_quantity > 500
ORDER BY p_top.name, p_item.name;