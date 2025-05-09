/* “Fallback” implementation that relies solely on the two tables that are
   confirmed to exist (BATTING + PLAYER).  
   It treats the numeric strike–out total (“SO”) recorded for pitchers in
   the BATTING table as the measurable “speed-like” metric, then returns the
   player with the highest non-zero value for every team. */

WITH PLAYER_TEAM_MAX AS (
    SELECT
        "TEAM_ID",
        "PLAYER_ID",
        MAX( TRY_TO_NUMBER("SO") ) AS "MAX_SPEED"
    FROM BASEBALL.BASEBALL."BATTING"
    WHERE TRY_TO_NUMBER("SO") > 0                -- keep only valid, non-zero
    GROUP BY "TEAM_ID", "PLAYER_ID"
),
BEST_BY_TEAM AS (
    SELECT
        "TEAM_ID",
        "PLAYER_ID",
        "MAX_SPEED",
        ROW_NUMBER() OVER (PARTITION BY "TEAM_ID"
                           ORDER BY "MAX_SPEED" DESC) AS RN
    FROM PLAYER_TEAM_MAX
)
SELECT
       B."TEAM_ID",
       P."NAME_FIRST" || ' ' || P."NAME_LAST"   AS "FULL_NAME",
       B."MAX_SPEED"
FROM   BEST_BY_TEAM                B
JOIN   BASEBALL.BASEBALL."PLAYER"  P
       ON P."PLAYER_ID" = B."PLAYER_ID"
WHERE  B.RN = 1
ORDER  BY B."TEAM_ID" NULLS LAST;