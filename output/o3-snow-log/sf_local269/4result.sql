WITH RECURSIVE
/* direct relations */
"REL" AS (
    SELECT  "packaging_id",
            "contains_id",
            "qty"
    FROM    ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS
),

/* recursively explode every packaging into its leaf components */
"EXPANDED" ("root_id", "leaf_id", "total_qty") AS (
    /* anchor : first level children */
    SELECT  r."packaging_id",
            r."contains_id",
            CAST(r."qty" AS FLOAT)
    FROM    "REL" r

    UNION ALL

    /* recursion : keep drilling while the current leaf is itself a parent */
    SELECT  e."root_id",
            r."contains_id",
            e."total_qty" * r."qty"
    FROM    "EXPANDED" e
    JOIN    "REL"      r
           ON e."leaf_id" = r."packaging_id"
),

/* determine which ids are true leaves (never appear as a parent) */
"LEAF_IDS" AS (
    SELECT DISTINCT e."leaf_id"
    FROM   "EXPANDED" e
    LEFT  JOIN "REL"  r
           ON e."leaf_id" = r."packaging_id"
    WHERE  r."packaging_id" IS NULL          -- keep only genuine leaves
),

/* total leaf-level quantity per top-level packaging */
"TOTAL_PER_PACKAGING" AS (
    SELECT  e."root_id"            AS "packaging_id",
            SUM(e."total_qty")     AS "total_qty"
    FROM    "EXPANDED" e
    JOIN    "LEAF_IDS" l
           ON e."leaf_id" = l."leaf_id"
    GROUP BY e."root_id"
)

/* final answer: average of those totals */
SELECT  ROUND(AVG("total_qty"), 4) AS "avg_total_leaf_quantity"
FROM    "TOTAL_PER_PACKAGING";