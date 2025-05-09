WITH RECURSIVE

/* ----------------------------------------------------------
   1. True leaf items – IDs that never act as a parent
----------------------------------------------------------*/
leaf_ids AS (
    SELECT DISTINCT pr."contains_id" AS id
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
    WHERE pr."contains_id" NOT IN (
          SELECT DISTINCT "packaging_id"
          FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS
    )
),

/* ----------------------------------------------------------
   2. Recursively explode every package down to its leaf items
----------------------------------------------------------*/
hier AS (
    /* level-0 : direct children */
    SELECT
        pr."packaging_id" AS root_id,
        pr."contains_id"  AS current_id,
        pr."qty"          AS qty_cum
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr

    UNION ALL

    /* deeper levels : multiply quantities along the path */
    SELECT
        h.root_id,
        pr2."contains_id",
        h.qty_cum * pr2."qty"  AS qty_cum
    FROM hier h
    JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr2
      ON pr2."packaging_id" = h.current_id
),

/* ----------------------------------------------------------
   3. Total quantity of leaf items per original package
----------------------------------------------------------*/
totals AS (
    SELECT
        h.root_id            AS packaging_id,
        SUM(h.qty_cum)       AS total_leaf_qty
    FROM hier h
    WHERE h.current_id IN (SELECT id FROM leaf_ids)
    GROUP BY h.root_id
)

/* ----------------------------------------------------------
   4. Average total quantity across all packages
----------------------------------------------------------*/
SELECT
    AVG(total_leaf_qty) AS avg_total_leaf_qty
FROM totals;