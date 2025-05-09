WITH player_runs_per_match AS (      -- total runs a player scores in every match
    SELECT
        BB."striker"  AS "player_id",
        BB."match_id",
        SUM(BS."runs_scored") AS "runs_in_match"
    FROM IPL.IPL.BALL_BY_BALL BB
    JOIN IPL.IPL.BATSMAN_SCORED BS
      ON BB."match_id"   = BS."match_id"
     AND BB."over_id"    = BS."over_id"
     AND BB."ball_id"    = BS."ball_id"
     AND BB."innings_no" = BS."innings_no"
    GROUP BY
        BB."striker",
        BB."match_id"
),
player_avg_runs AS (                -- each player’s average runs per match
    SELECT
        "player_id",
        AVG("runs_in_match") AS "avg_runs_per_match"
    FROM player_runs_per_match
    GROUP BY
        "player_id"
),
country_avg AS (                    -- average of player-averages for every country
    SELECT
        PL."country_name",
        AVG(PA."avg_runs_per_match") AS "country_avg_runs_per_match"
    FROM player_avg_runs PA
    JOIN IPL.IPL.PLAYER PL
      ON PL."player_id" = PA."player_id"
    GROUP BY
        PL."country_name"
)
SELECT
    "country_name",
    ROUND("country_avg_runs_per_match", 4) AS "country_batting_average"
FROM country_avg
ORDER BY
    "country_batting_average" DESC NULLS LAST
LIMIT 5;