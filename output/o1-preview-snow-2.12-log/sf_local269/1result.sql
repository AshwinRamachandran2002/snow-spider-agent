WITH RECURSIVE packaging_hierarchy AS (
    SELECT
        pr."packaging_id" AS "top_packaging_id",
        pr."contains_id" AS "packaging_id",
        pr."qty" AS "quantity"
    FROM
        "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr
    WHERE
        pr."packaging_id" IN (
            SELECT p."id"
            FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" p
            WHERE p."id" NOT IN (
                SELECT DISTINCT pr2."contains_id"
                FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr2
            )
        )
    UNION ALL
    SELECT
        ph."top_packaging_id",
        pr."contains_id" AS "packaging_id",
        ph."quantity" * pr."qty" AS "quantity"
    FROM packaging_hierarchy ph
    JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr
        ON ph."packaging_id" = pr."packaging_id"
)
SELECT
    AVG(total_quantity) AS "average_total_quantity"
FROM
(
    SELECT
        ph."top_packaging_id",
        SUM(ph."quantity") AS total_quantity
    FROM packaging_hierarchy ph
    WHERE ph."packaging_id" IN (
        SELECT p_leaf."id"
        FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" p_leaf
        WHERE p_leaf."id" NOT IN (
            SELECT DISTINCT pr3."packaging_id"
            FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr3
        )
    )
    GROUP BY ph."top_packaging_id"
);