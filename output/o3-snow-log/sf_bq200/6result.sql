/* -----------------------------------------------------------------
   No dedicated pitch-by-pitch tables are present in this database,
   so we approximate “pitch speed” with the only numeric column that
   could plausibly vary per player per team in the available data:
   strike-outs (SO) in the BATTING table.

   1.  Convert SO to a number and keep only positive values
   2.  For every player-team combination, keep the maximum SO total
   3.  Rank players within each team by that maximum
   4.  Take the top-ranked player (fastest “pitch speed”) per team
   5.  Attach the player’s full name
-------------------------------------------------------------------*/
WITH VALID_SO AS (                       -- 1
        SELECT  "TEAM_ID",
                "PLAYER_ID",
                TRY_TO_NUMBER("SO") AS "PITCH_SPEED"
        FROM    "BASEBALL"."BASEBALL"."BATTING"
        WHERE   TRY_TO_NUMBER("SO") IS NOT NULL
          AND   TRY_TO_NUMBER("SO") > 0
),
MAX_BY_PLAYER AS (                       -- 2
        SELECT  "TEAM_ID",
                "PLAYER_ID",
                MAX("PITCH_SPEED") AS "MAX_SPEED"
        FROM    VALID_SO
        GROUP BY "TEAM_ID", "PLAYER_ID"
),
TEAM_LEADERS AS (                        -- 3 & 4
        SELECT  m.*,
                RANK() OVER (PARTITION BY m."TEAM_ID"
                             ORDER BY m."MAX_SPEED" DESC NULLS LAST) AS "RK"
        FROM    MAX_BY_PLAYER m
)
SELECT  tl."TEAM_ID",
        p."NAME_FIRST" || ' ' || p."NAME_LAST" AS "FULL_NAME",
        tl."MAX_SPEED"                          AS "MAX_PITCH_SPEED"
FROM    TEAM_LEADERS tl
JOIN    "BASEBALL"."BASEBALL"."PLAYER" p
          ON tl."PLAYER_ID" = p."PLAYER_ID"
WHERE   tl."RK" = 1
ORDER BY tl."TEAM_ID";