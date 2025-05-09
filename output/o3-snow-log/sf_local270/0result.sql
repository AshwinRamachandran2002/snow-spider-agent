/*  Return every top-level packaging container (never itself contained in another)
    that holds any item whose accumulated quantity through the whole hierarchy
    exceeds 500 – together with the human-readable names of both container and item  */

WITH RECURSIVE
-- 1. identify top-level containers
top_pkg AS (
    SELECT DISTINCT pr."packaging_id"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
    WHERE pr."packaging_id" NOT IN (
          SELECT DISTINCT "contains_id"
          FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS )
),

-- 2. walk the packaging hierarchy, multiplying quantities on the way down
r (top_id, curr_id, total_qty) AS (
    /* level 0 : each root counts as one of itself */
    SELECT tp."packaging_id", tp."packaging_id", 1::FLOAT
    FROM   top_pkg tp
    UNION ALL
    /* recurse one step deeper and accumulate quantity */
    SELECT r.top_id,
           pr."contains_id",
           r.total_qty * pr."qty"
    FROM   r
    JOIN   ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
           ON pr."packaging_id" = r.curr_id
),

-- 3. collapse possible multiple paths to the same (top_id , item) pair
summed AS (
    SELECT  top_id,
            curr_id,
            SUM(total_qty) AS total_qty
    FROM    r
    GROUP BY top_id, curr_id
    HAVING  SUM(total_qty) > 500          -- keep only big-quantity items
)

-- 4. attach readable names and output result
SELECT  p_top."name"                                          AS "top_level_container",
        COALESCE(p_item."name", CAST(s.curr_id AS VARCHAR))   AS "contained_item"
FROM    summed                          s
JOIN    ORACLE_SQL.ORACLE_SQL.PACKAGING p_top
          ON p_top."id" = s.top_id
LEFT JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING p_item
          ON p_item."id" = s.curr_id
ORDER BY p_top."name", "contained_item";