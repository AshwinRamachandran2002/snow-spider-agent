WITH RECURSIVE
    rel AS (                          -- direct relations
        SELECT
            "packaging_id",
            "contains_id",
            "qty"::FLOAT AS qty
        FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS
    ),

    exp (root_id, item_id, total_qty) AS (   -- expand nested relations
        /* anchor level */
        SELECT
            "packaging_id"  AS root_id,
            "contains_id"   AS item_id,
            qty             AS total_qty
        FROM rel

        UNION ALL                            -- recursive step
        SELECT
            e.root_id,
            r."contains_id",
            e.total_qty * r.qty
        FROM exp e
        JOIN rel r
          ON r."packaging_id" = e.item_id
    ),

    leaf_totals AS (                         -- sum quantities of leaf items
        SELECT
            root_id,
            SUM(total_qty) AS total_leaf_qty
        FROM exp
        WHERE item_id NOT IN (SELECT DISTINCT "packaging_id" FROM rel)
        GROUP BY root_id
    )

SELECT
    ROUND(AVG(total_leaf_qty), 4) AS AVG_TOTAL_LEAF_QTY
FROM leaf_totals;