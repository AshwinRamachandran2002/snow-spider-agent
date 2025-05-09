WITH RECURSIVE cte(root_packaging_id, contains_id, qty) AS (
    -- Start with final packaging_ids (final packaging combinations)
    SELECT
        pr.packaging_id AS root_packaging_id,
        pr.contains_id,
        pr.qty
    FROM
        packaging_relations pr
    WHERE
        pr.packaging_id NOT IN (
            SELECT contains_id FROM packaging_relations
        )
    UNION ALL
    -- Recursively traverse nested packaging relationships
    SELECT
        cte.root_packaging_id,
        pr.contains_id,
        cte.qty * pr.qty
    FROM
        cte
    JOIN packaging_relations pr ON cte.contains_id = pr.packaging_id
)
SELECT
    AVG(total_qty) AS average_total_quantity
FROM (
    -- Calculate total quantities for each final packaging
    SELECT
        root_packaging_id,
        SUM(qty) AS total_qty
    FROM
        cte
    WHERE
        contains_id NOT IN (SELECT packaging_id FROM packaging_relations)
    GROUP BY
        root_packaging_id
)