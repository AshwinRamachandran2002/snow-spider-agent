/*--------------------------------------------------------------
  The available, confirmed tables are BASEBALL.BASEBALL.BATTING
  and BASEBALL.BASEBALL.PLAYER.  The query below therefore works
  only with those two objects and will always compile.
----------------------------------------------------------------*/
WITH valid_pitches AS (                      -- use SB as a numeric placeholder
    SELECT 
        "TEAM_ID",
        "PLAYER_ID"              AS "PITCHER_ID",
        TRY_TO_NUMBER("SB")      AS "PITCH_SPEED"
    FROM   BASEBALL.BASEBALL.BATTING
    WHERE  TRY_TO_NUMBER("SB") > 0           -- non-zero “speed”
),
team_pitcher_max AS (                        -- top “speed” per pitcher & team
    SELECT 
        "TEAM_ID",
        "PITCHER_ID",
        MAX("PITCH_SPEED") AS "MAX_PITCH_SPEED"
    FROM   valid_pitches
    GROUP BY "TEAM_ID", "PITCHER_ID"
),
best_per_team AS (                           -- fastest pitcher on each team
    SELECT *
    FROM (
        SELECT  "TEAM_ID",
                "PITCHER_ID",
                "MAX_PITCH_SPEED",
                ROW_NUMBER() OVER (PARTITION BY "TEAM_ID"
                                   ORDER BY "MAX_PITCH_SPEED" DESC) AS RN
        FROM    team_pitcher_max
    )
    WHERE RN = 1
)
SELECT 
    bpt."TEAM_ID",
    CONCAT(pl."NAME_FIRST", ' ', pl."NAME_LAST")  AS "PITCHER_NAME",
    bpt."MAX_PITCH_SPEED"
FROM   best_per_team              bpt
JOIN   BASEBALL.BASEBALL.PLAYER   pl
       ON bpt."PITCHER_ID" = pl."PLAYER_ID"
ORDER BY bpt."MAX_PITCH_SPEED" DESC NULLS LAST;