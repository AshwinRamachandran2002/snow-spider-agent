SELECT
    top_pack."name" AS "Container_Name",
    leaf_pack."name" AS "Item_Name"
FROM
    "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" top_pack
JOIN
    "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr1
    ON top_pack."id" = pr1."packaging_id"
JOIN
    "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" mid_pack
    ON pr1."contains_id" = mid_pack."id"
JOIN
    "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr2
    ON mid_pack."id" = pr2."packaging_id"
JOIN
    "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" leaf_pack
    ON pr2."contains_id" = leaf_pack."id"
WHERE
    top_pack."id" NOT IN (
        SELECT DISTINCT pr."contains_id"
        FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr
    )
GROUP BY
    top_pack."name",
    leaf_pack."name"
HAVING
    SUM(pr1."qty" * pr2."qty") > 500;