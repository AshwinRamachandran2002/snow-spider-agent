WITH RECURSIVE
    leaf_items AS (
        SELECT id
        FROM packaging
        WHERE id NOT IN (SELECT packaging_id FROM packaging_relations)
    ),
    final_packaging AS (
        SELECT id
        FROM packaging
        WHERE id NOT IN (SELECT contains_id FROM packaging_relations)
    ),
    cte(packaging_id, item_id, quantity) AS (
        SELECT pr.packaging_id, pr.contains_id, pr.qty
        FROM packaging_relations pr
        WHERE pr.packaging_id IN (SELECT id FROM final_packaging)
        UNION ALL
        SELECT cte.packaging_id, pr.contains_id, cte.quantity * pr.qty
        FROM cte
        JOIN packaging_relations pr ON cte.item_id = pr.packaging_id
    ),
    total_quantities AS (
        SELECT packaging_id, SUM(quantity) AS total_quantity
        FROM (
            SELECT cte.packaging_id, cte.item_id, cte.quantity
            FROM cte
            WHERE cte.item_id IN (SELECT id FROM leaf_items)
        )
        GROUP BY packaging_id
    )
SELECT AVG(total_quantity) AS average_total_quantity
FROM total_quantities;