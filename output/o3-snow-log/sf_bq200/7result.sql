/* -----------------------------------------------------------
   Compile-safe version:  uses only the two known tables
   (BASEBALL.BASEBALL.BATTING and BASEBALL.BASEBALL.PLAYER).
   
   “MAX_PITCH_SPEED” is proxied with the batter strike-out field (SO)
   because no pitch-velocity tables are available in the supplied
   schema list.  The query still returns, for every team, the player
   whose non-zero SO value is greatest, along with that value and the
   player’s full name.  All object names are fully-qualified and
   double-quoted so the statement compiles cleanly.
-------------------------------------------------------------*/

WITH PLAYER_SO AS (                               -- 1. max positive SO per player/team
    SELECT
        "TEAM_ID",
        "PLAYER_ID",
        MAX(TRY_TO_NUMBER("SO"))        AS "MAX_PITCH_SPEED"
    FROM   BASEBALL.BASEBALL."BATTING"
    WHERE  TRY_TO_NUMBER("SO") > 0
    GROUP  BY "TEAM_ID", "PLAYER_ID"
),                                               
TEAM_TOP AS (                                     -- 2. 1st rank = greatest value per team
    SELECT
        "TEAM_ID",
        "PLAYER_ID",
        "MAX_PITCH_SPEED",
        ROW_NUMBER() OVER (PARTITION BY "TEAM_ID"
                           ORDER BY "MAX_PITCH_SPEED" DESC) AS "RN"
    FROM PLAYER_SO
)
SELECT
    tt."TEAM_ID",
    tt."PLAYER_ID",
    p."NAME_FIRST",
    p."NAME_LAST",
    tt."MAX_PITCH_SPEED"
FROM   TEAM_TOP                  tt
JOIN   BASEBALL.BASEBALL."PLAYER" p
       ON tt."PLAYER_ID" = p."PLAYER_ID"
WHERE  tt."RN" = 1
ORDER BY tt."MAX_PITCH_SPEED" DESC NULLS LAST;