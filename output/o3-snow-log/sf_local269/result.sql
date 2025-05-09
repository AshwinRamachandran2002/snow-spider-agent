WITH RECURSIVE
/*------------------------------------------------------------------
1.  Collect every packaging_id that acts as a “root” combination
------------------------------------------------------------------*/
"ROOTS" AS (
    SELECT DISTINCT "packaging_id"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS
),

/*------------------------------------------------------------------
2.  Expand every root down to all descendant items, multiplying the
    quantities as we go so each row holds the true amount that
    particular path contributes.
------------------------------------------------------------------*/
"PACK_HIERARCHY" AS (
    /* level-0 : direct children of each root */
    SELECT  PR."packaging_id"   AS "root_id",
            PR."contains_id"    AS "item_id",
            CAST(PR."qty" AS FLOAT) AS "acc_qty"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS PR
    
    UNION ALL
    
    /* recurse while current item also appears as a parent */
    SELECT  PH."root_id",
            PR2."contains_id",
            PH."acc_qty" * PR2."qty"
    FROM   "PACK_HIERARCHY" PH
           JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS PR2
             ON PH."item_id" = PR2."packaging_id"
),

/*------------------------------------------------------------------
3.  Keep only leaf-level items (those that never act as parents) and
    sum their quantities per root combination.
------------------------------------------------------------------*/
"LEAF_TOTALS" AS (
    SELECT  PH."root_id",
            SUM(PH."acc_qty") AS "total_leaf_qty"
    FROM    "PACK_HIERARCHY" PH
            LEFT JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS NX
                   ON PH."item_id" = NX."packaging_id"
    WHERE   NX."packaging_id" IS NULL        -- retain only leaves
    GROUP BY PH."root_id"
)

/*------------------------------------------------------------------
4.  Average the total leaf quantities across all root combinations
------------------------------------------------------------------*/
SELECT  AVG("total_leaf_qty") AS "avg_total_leaf_qty"
FROM    "LEAF_TOTALS";