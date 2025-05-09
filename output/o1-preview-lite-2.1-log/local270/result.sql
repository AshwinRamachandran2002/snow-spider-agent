WITH RECURSIVE packaging_contents(packaging_id, contains_id, qty) AS (
    SELECT
        pr.packaging_id,
        pr.contains_id,
        pr.qty
    FROM
        packaging_relations pr
    UNION ALL
    SELECT
        pc.packaging_id,
        pr.contains_id,
        pc.qty * pr.qty
    FROM
        packaging_contents pc
    JOIN packaging_relations pr ON pc.contains_id = pr.packaging_id
)
SELECT
    p.id AS packaging_id,
    p.name AS packaging_name,
    SUM(pc.qty) AS total_quantity
FROM
    packaging_contents pc
JOIN packaging p ON pc.packaging_id = p.id
WHERE
    pc.contains_id IN (501, 502)
GROUP BY
    p.id, p.name
HAVING
    SUM(pc.qty) > 500;