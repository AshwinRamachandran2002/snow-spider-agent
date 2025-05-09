WITH final_packaging AS (
    SELECT "id"
    FROM ORACLE_SQL.ORACLE_SQL."PACKAGING"
    WHERE "id" NOT IN (
        SELECT DISTINCT "contains_id"
        FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS"
    )
),
cte("packaging_id", "contains_id", "total_qty", "final_packaging_id") AS (
    -- Base case: start from the final packaging combinations
    SELECT
        pr."packaging_id",
        pr."contains_id",
        pr."qty" AS "total_qty",
        pr."packaging_id" AS "final_packaging_id"
    FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr
    WHERE pr."packaging_id" IN (SELECT "id" FROM final_packaging)
    UNION ALL
    -- Recursive case: expand contained items
    SELECT
        pr."packaging_id",
        pr."contains_id",
        cte."total_qty" * pr."qty" AS "total_qty",
        cte."final_packaging_id"
    FROM cte
    JOIN ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr ON cte."contains_id" = pr."packaging_id"
)
SELECT ROUND(AVG("total_quantity"), 4) AS "average_total_quantity"
FROM (
    SELECT
        cte."final_packaging_id",
        SUM(
            CASE
                WHEN cte."contains_id" NOT IN (
                    SELECT DISTINCT "packaging_id"
                    FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS"
                ) THEN cte."total_qty"
                ELSE 0
            END
        ) AS "total_quantity"
    FROM cte
    GROUP BY cte."final_packaging_id"
) sub;