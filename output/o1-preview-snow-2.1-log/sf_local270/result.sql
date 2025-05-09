WITH RECURSIVE packaging_hierarchy AS (
    SELECT
        pr."packaging_id" AS "top_packaging_id",
        pr."contains_id",
        pr."qty" AS "cumulative_qty",
        ARRAY_CONSTRUCT(TO_VARIANT(pr."packaging_id"), TO_VARIANT(pr."contains_id")) AS "path"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr

    UNION ALL

    SELECT
        r."top_packaging_id",
        pr."contains_id",
        r."cumulative_qty" * pr."qty" AS "cumulative_qty",
        ARRAY_APPEND(r."path", TO_VARIANT(pr."contains_id"))
    FROM packaging_hierarchy r
    JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr
        ON r."contains_id" = pr."packaging_id"
    WHERE NOT ARRAY_CONTAINS(r."path", TO_VARIANT(pr."contains_id"))
)
, packaging_ids AS (
    SELECT DISTINCT "packaging_id" FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS"
)
, leaf_items AS (
    SELECT DISTINCT "contains_id" AS "item_id" FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS"
    WHERE "contains_id" NOT IN (SELECT "packaging_id" FROM packaging_ids)
)
SELECT
    p."id" AS "packaging_id",
    p."name",
    TO_DECIMAL(SUM(ph."cumulative_qty"), 10, 4) AS "total_quantity"
FROM packaging_hierarchy ph
JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" p ON ph."top_packaging_id" = p."id"
WHERE ph."contains_id" IN (SELECT "item_id" FROM leaf_items)
GROUP BY p."id", p."name"
HAVING SUM(ph."cumulative_qty") > 500
ORDER BY p."id";