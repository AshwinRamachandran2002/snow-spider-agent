WITH RECURSIVE
    "top_packaging"("packaging_id", "name") AS (
        SELECT "id", "name"
        FROM "packaging"
        WHERE "id" NOT IN (SELECT "contains_id" FROM "packaging_relations")
    ),
    "recursive_hierarchy"("packaging_id", "contains_id", "total_qty") AS (
        -- Base case: direct child relationships of top-level packages
        SELECT pr."packaging_id", pr."contains_id", pr."qty"
        FROM "packaging_relations" pr
        JOIN "top_packaging" tp ON tp."packaging_id" = pr."packaging_id"
        UNION ALL
        -- Recursive step: expand further where contains_id is a packaging_id
        SELECT rh."packaging_id", pr."contains_id", rh."total_qty" * pr."qty"
        FROM "recursive_hierarchy" rh
        JOIN "packaging_relations" pr ON pr."packaging_id" = rh."contains_id"
    )
SELECT
    AVG("total_leaf_qty") AS "average_total_quantity"
FROM (
    SELECT
        rh."packaging_id",
        SUM(rh."total_qty") AS "total_leaf_qty"
    FROM "recursive_hierarchy" rh
    WHERE rh."contains_id" NOT IN (SELECT "packaging_id" FROM "packaging_relations")  -- leaf items
    GROUP BY rh."packaging_id"
) totals;