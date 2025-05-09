WITH RECURSIVE
/* base table */
REL AS (
    SELECT "packaging_id",
           "contains_id",
           "qty"::FLOAT AS "qty"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS
),
/* walk the hierarchy – multiply the quantity on every step */
HIER AS (
    /* level-0 (direct children) */
    SELECT  r."packaging_id"          AS "root_id",
            r."contains_id",
            r."qty"                   AS "qty_path"
    FROM    REL r

    UNION ALL

    /* deeper levels */
    SELECT  h."root_id",
            r2."contains_id",
            h."qty_path" * r2."qty"   AS "qty_path"
    FROM    HIER h
    JOIN    REL  r2
           ON r2."packaging_id" = h."contains_id"
),
/* keep only leaf-level items (those that are never a packaging_id themselves) */
LEAVES AS (
    SELECT  h."root_id",
            h."qty_path"
    FROM    HIER h
    LEFT JOIN REL r
           ON r."packaging_id" = h."contains_id"
    WHERE   r."packaging_id" IS NULL
),
/* total quantity for every root packaging combination */
TOTALS AS (
    SELECT  "root_id",
            SUM("qty_path") AS "total_qty"
    FROM    LEAVES
    GROUP BY "root_id"
)
/* average of those totals */
SELECT AVG("total_qty") AS "avg_total_qty"
FROM   TOTALS;