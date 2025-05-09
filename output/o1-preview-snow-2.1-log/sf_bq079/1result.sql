SELECT 'Timberland' AS "Category", T."state_code", T."evaluation_group", T."state_name", ROUND(T."total_acres", 4) AS "total_acres"
FROM (
    SELECT "state_code", "evaluation_group", "state_name", SUM("subplot_acres") AS "total_acres"
    FROM USFS_FIA.USFS_FIA.ESTIMATED_TIMBERLAND_ACRES
    WHERE "evaluation_group" = (
        SELECT MAX("evaluation_group") FROM USFS_FIA.USFS_FIA.ESTIMATED_TIMBERLAND_ACRES
    )
    GROUP BY "state_code", "evaluation_group", "state_name"
    ORDER BY "total_acres" DESC NULLS LAST
    LIMIT 1
) T
UNION ALL
SELECT 'Forestland' AS "Category", F."state_code", F."evaluation_group", F."state_name", ROUND(F."total_acres", 4) AS "total_acres"
FROM (
    SELECT "state_code", "evaluation_group", "state_name", SUM("subplot_acres") AS "total_acres"
    FROM USFS_FIA.USFS_FIA.ESTIMATED_FORESTLAND_ACRES
    WHERE "evaluation_group" = (
        SELECT MAX("evaluation_group") FROM USFS_FIA.USFS_FIA.ESTIMATED_FORESTLAND_ACRES
    )
    GROUP BY "state_code", "evaluation_group", "state_name"
    ORDER BY "total_acres" DESC NULLS LAST
    LIMIT 1
) F;