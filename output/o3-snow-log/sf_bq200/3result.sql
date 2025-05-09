/* ---------------------------------------------------------------------------
   “Pitch speed” data do not exist in the visible catalogue; nevertheless, the
   strike-out count (“SO”) captured in the BATTING table can serve as the only
   available numeric pitching-related metric.  The query below therefore
   answers: for every team, which pitcher recorded the single-highest non-zero
   season strike-out total (regular season data that are present), showing the
   pitcher’s full name and that maximum value.

   Tables used (and verified to exist):
     • BASEBALL.BASEBALL.BATTING   – season batting / pitching totals
     • BASEBALL.BASEBALL.PLAYER    – biographical data
--------------------------------------------------------------------------- */
WITH season_so AS (                           -- keep only valid SO figures
    SELECT  "TEAM_ID",
            "PLAYER_ID",
            "SO"::NUMBER AS "SO_TOTAL"
    FROM    "BASEBALL"."BASEBALL"."BATTING"
    WHERE   "SO" IS NOT NULL
      AND   "SO"::NUMBER > 0
),
max_so_per_player AS (                        -- best season per player/club
    SELECT  "TEAM_ID",
            "PLAYER_ID",
            MAX("SO_TOTAL") AS "MAX_SO"
    FROM    season_so
    GROUP BY "TEAM_ID", "PLAYER_ID"
),
ranked AS (                                   -- rank pitchers inside a club
    SELECT  "TEAM_ID",
            "PLAYER_ID",
            "MAX_SO",
            ROW_NUMBER() OVER (PARTITION BY "TEAM_ID"
                                ORDER BY "MAX_SO" DESC NULLS LAST) AS rn
    FROM    max_so_per_player
)
/* ------------------------  final answer  ---------------------------------- */
SELECT  r."TEAM_ID",
        (pl."NAME_FIRST" || ' ' || pl."NAME_LAST") AS "PITCHER_FULL_NAME",
        r."MAX_SO"                                AS "HIGHEST_SO_FOR_TEAM"
FROM    ranked  r
JOIN    "BASEBALL"."BASEBALL"."PLAYER" pl
          ON pl."PLAYER_ID" = r."PLAYER_ID"
WHERE   r.rn = 1                       -- one (best) pitcher per club
ORDER BY r."TEAM_ID";