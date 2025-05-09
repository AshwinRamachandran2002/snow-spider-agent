/*-----------------------------------------------------------------
  Approximate “pitch speed” with the strike-out (SO) totals in the
  available tables.  For every team, find the player who posted the
  highest non-zero single-season SO value and return the player’s
  full name together with that maximum figure.
------------------------------------------------------------------*/
WITH "SO_NUMERIC" AS (                       -- keep rows with a numeric SO > 0
    SELECT  "TEAM_ID",
            "PLAYER_ID",
            TRY_TO_NUMBER("SO") AS "SO_N"
    FROM    BASEBALL.BASEBALL.BATTING
    WHERE   TRY_TO_NUMBER("SO") > 0
),
"MAX_SO_BY_PITCHER_TEAM" AS (                -- best SO per player / team
    SELECT  "TEAM_ID",
            "PLAYER_ID",
            MAX("SO_N") AS "MAX_SO"
    FROM    "SO_NUMERIC"
    GROUP BY "TEAM_ID", "PLAYER_ID"
),
"FASTEST_PER_TEAM_APPROX" AS (               -- keep top SO per team
    SELECT  "TEAM_ID",
            "PLAYER_ID",
            "MAX_SO",
            ROW_NUMBER() OVER (PARTITION BY "TEAM_ID"
                               ORDER BY "MAX_SO" DESC NULLS LAST) AS "RN"
    FROM    "MAX_SO_BY_PITCHER_TEAM"
)
SELECT  f."TEAM_ID",
        p."NAME_FIRST" || ' ' || p."NAME_LAST" AS "PITCHER_NAME",
        TO_DECIMAL(f."MAX_SO", 10, 0)          AS "MAX_VALID_PITCH_SPEED"
FROM    "FASTEST_PER_TEAM_APPROX" f
JOIN    BASEBALL.BASEBALL.PLAYER   p
       ON p."PLAYER_ID" = f."PLAYER_ID"
WHERE   f."RN" = 1
ORDER BY "MAX_VALID_PITCH_SPEED" DESC NULLS LAST;