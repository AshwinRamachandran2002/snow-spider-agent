SELECT AVG(total_nested_qty) AS "average_total_quantity"
FROM (
    SELECT
        pr1.packaging_id,
        SUM(
            CASE
                WHEN pr2.qty IS NOT NULL THEN pr1.qty * pr2.qty
                ELSE pr1.qty
            END
        ) AS total_nested_qty
    FROM
        "packaging_relations" pr1
        LEFT JOIN "packaging_relations" pr2 ON pr1.contains_id = pr2.packaging_id
    WHERE
        pr1.packaging_id IN (
            SELECT p.id FROM "packaging" p
            WHERE p.id NOT IN (SELECT pr.contains_id FROM "packaging_relations" pr)
        )
    GROUP BY
        pr1.packaging_id
);