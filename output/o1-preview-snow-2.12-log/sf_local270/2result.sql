SELECT
    totals."Container_Name",
    totals."Item_Name"
FROM (
    -- Direct contents
    SELECT
        top_p."name" AS "Container_Name",
        item_p."name" AS "Item_Name",
        SUM(pr1."qty") AS "Total_Qty"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS top_p
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" AS pr1
        ON top_p."id" = pr1."packaging_id"
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS item_p
        ON pr1."contains_id" = item_p."id"
    WHERE top_p."id" NOT IN (
        SELECT DISTINCT "contains_id" FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS"
    )
    GROUP BY top_p."name", item_p."name"

    UNION ALL

    -- One level deep
    SELECT
        top_p."name" AS "Container_Name",
        item_p."name" AS "Item_Name",
        SUM(pr1."qty" * pr2."qty") AS "Total_Qty"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS top_p
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" AS pr1
        ON top_p."id" = pr1."packaging_id"
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS mid_p
        ON pr1."contains_id" = mid_p."id"
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" AS pr2
        ON mid_p."id" = pr2."packaging_id"
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS item_p
        ON pr2."contains_id" = item_p."id"
    WHERE top_p."id" NOT IN (
        SELECT DISTINCT "contains_id" FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS"
    )
    GROUP BY top_p."name", item_p."name"

    UNION ALL

    -- Two levels deep
    SELECT
        top_p."name" AS "Container_Name",
        item_p."name" AS "Item_Name",
        SUM(pr1."qty" * pr2."qty" * pr3."qty") AS "Total_Qty"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS top_p
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" AS pr1
        ON top_p."id" = pr1."packaging_id"
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS mid_p1
        ON pr1."contains_id" = mid_p1."id"
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" AS pr2
        ON mid_p1."id" = pr2."packaging_id"
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS mid_p2
        ON pr2."contains_id" = mid_p2."id"
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" AS pr3
        ON mid_p2."id" = pr3."packaging_id"
    INNER JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS item_p
        ON pr3."contains_id" = item_p."id"
    WHERE top_p."id" NOT IN (
        SELECT DISTINCT "contains_id" FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS"
    )
    GROUP BY top_p."name", item_p."name"

) AS totals
WHERE totals."Total_Qty" > 500
ORDER BY totals."Container_Name", totals."Item_Name";