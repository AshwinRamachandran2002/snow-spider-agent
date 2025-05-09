WITH runs_per_player_match AS (   -- total runs a player scores in each match
    SELECT
        bb."match_id",
        bb."striker"          AS "player_id",
        SUM(bs."runs_scored") AS "runs_in_match"
    FROM IPL.IPL.BALL_BY_BALL   bb
    JOIN IPL.IPL.BATSMAN_SCORED bs
      ON  bb."match_id"   = bs."match_id"
      AND bb."innings_no" = bs."innings_no"
      AND bb."over_id"    = bs."over_id"
      AND bb."ball_id"    = bs."ball_id"
    GROUP BY
        bb."match_id",
        bb."striker"
),
player_avg AS (                   -- each player’s average runs per match
    SELECT
        "player_id",
        AVG("runs_in_match") AS "player_avg_runs"
    FROM runs_per_player_match
    GROUP BY "player_id"
),
country_avg AS (                  -- average of player-averages for every country
    SELECT
        pl."country_name",
        AVG(pa."player_avg_runs") AS "country_batting_avg"
    FROM player_avg            pa
    JOIN IPL.IPL.PLAYER        pl
      ON pa."player_id" = pl."player_id"
    GROUP BY pl."country_name"
)
SELECT
    "country_name",
    ROUND("country_batting_avg", 4) AS "country_batting_avg"
FROM country_avg
ORDER BY "country_batting_avg" DESC NULLS LAST
LIMIT 5;