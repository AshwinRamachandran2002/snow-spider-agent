WITH RECURSIVE
    base_items(id) AS (
        SELECT "id" FROM "packaging"
        WHERE "id" NOT IN (SELECT "packaging_id" FROM "packaging_relations")
    ),
    container_contents("packaging_id", total_qty) AS (
        -- Base case: Containers directly containing base items
        SELECT pr."packaging_id", pr."qty"
        FROM "packaging_relations" pr
        WHERE pr."contains_id" IN (SELECT "id" FROM base_items)
        UNION ALL
        -- Recursive case: Containers containing other containers
        SELECT pr."packaging_id", cc.total_qty * pr."qty"
        FROM "packaging_relations" pr
        JOIN container_contents cc ON pr."contains_id" = cc."packaging_id"
    )
SELECT
    p."id" AS "packaging_id",
    p."name" AS "packaging_name",
    SUM(container_contents.total_qty) AS "total_quantity"
FROM container_contents
JOIN "packaging" p ON p."id" = container_contents."packaging_id"
GROUP BY p."id", p."name"
HAVING SUM(container_contents.total_qty) > 500;