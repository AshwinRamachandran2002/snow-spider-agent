WITH RECURSIVE PackagingTree AS (
    -- Anchor member: start from top-level packaging containers
    SELECT
        pr.packaging_id AS top_container_id,
        pr.contains_id AS item_id,
        pr.qty AS qty
    FROM packaging_relations pr
    WHERE pr.packaging_id IN (
        SELECT id
        FROM packaging
        WHERE id NOT IN (
            SELECT DISTINCT contains_id
            FROM packaging_relations
        )
    )
    UNION ALL
    -- Recursive member: for each item, find if it contains other items
    SELECT
        pt.top_container_id,
        pr.contains_id AS item_id,
        pt.qty * pr.qty AS qty
    FROM PackagingTree pt
    JOIN packaging_relations pr ON pt.item_id = pr.packaging_id
)
SELECT
    p_top.name AS Container_Name,
    p_item.name AS Item_Name
FROM PackagingTree pt
JOIN packaging p_top ON pt.top_container_id = p_top.id
JOIN packaging p_item ON pt.item_id = p_item.id
GROUP BY pt.top_container_id, pt.item_id
HAVING SUM(pt.qty) > 500
ORDER BY Container_Name, Item_Name;