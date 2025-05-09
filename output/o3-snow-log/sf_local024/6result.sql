WITH runs_per_player_match AS (   -- runs scored by each player in every match
    SELECT
        bbb."striker"        AS "player_id",
        bbb."match_id"       AS "match_id",
        SUM(bs."runs_scored") AS "runs_in_match"
    FROM IPL.IPL.BATSMAN_SCORED   bs
    JOIN IPL.IPL.BALL_BY_BALL     bbb
      ON bs."match_id"   = bbb."match_id"
     AND bs."innings_no" = bbb."innings_no"
     AND bs."over_id"    = bbb."over_id"
     AND bs."ball_id"    = bbb."ball_id"
    GROUP BY
        bbb."striker",
        bbb."match_id"
),

total_runs_per_player AS (       -- total runs & matches played for every player
    SELECT
        pm."player_id"                                        AS "player_id",
        COALESCE(SUM(rpm."runs_in_match"), 0)                AS "total_runs",
        COUNT(DISTINCT pm."match_id")                        AS "matches_played"
    FROM IPL.IPL.PLAYER_MATCH           pm
    LEFT JOIN runs_per_player_match     rpm
           ON rpm."player_id" = pm."player_id"
          AND rpm."match_id"  = pm."match_id"
    GROUP BY
        pm."player_id"
),

player_avg AS (                  -- individual player average runs per match
    SELECT
        trp."player_id",
        CASE
            WHEN trp."matches_played" > 0
                 THEN trp."total_runs" / trp."matches_played"
            ELSE 0
        END AS "avg_runs_per_match"
    FROM total_runs_per_player trp
),

country_player_avg AS (          -- average of player-averages for every country
    SELECT
        pl."country_name",
        AVG(pa."avg_runs_per_match") AS "country_batting_avg"
    FROM player_avg               pa
    JOIN IPL.IPL.PLAYER           pl
      ON pa."player_id" = pl."player_id"
    GROUP BY
        pl."country_name"
)

SELECT
    "country_name",
    ROUND("country_batting_avg", 4) AS "country_batting_avg"
FROM country_player_avg
ORDER BY "country_batting_avg" DESC NULLS LAST
LIMIT 5;