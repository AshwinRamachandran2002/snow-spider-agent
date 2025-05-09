WITH ball_level_runs AS (               -- collapse any duplicate rows for the same ball
    SELECT
        "match_id",
        "innings_no",
        "over_id",
        "ball_id",
        SUM("runs_scored") AS "runs_scored"
    FROM "batsman_scored"
    GROUP BY "match_id", "innings_no", "over_id", "ball_id"
),
player_match_runs AS (                  -- runs a batter scored in a match
    SELECT
        b."match_id",
        b."striker" AS "player_id",
        SUM(r."runs_scored") AS "runs_in_match"
    FROM "ball_by_ball" b
    JOIN ball_level_runs r
      ON  b."match_id"   = r."match_id"
      AND b."innings_no" = r."innings_no"
      AND b."over_id"    = r."over_id"
      AND b."ball_id"    = r."ball_id"
    GROUP BY b."match_id", b."striker"
),
player_avg AS (                         -- each player’s average runs per match
    SELECT
        "player_id",
        AVG("runs_in_match") AS "avg_runs_per_match"
    FROM player_match_runs
    GROUP BY "player_id"
),
country_avg AS (                        -- country‑level average of those player averages
    SELECT
        p."country_name" AS "country",
        AVG(pa."avg_runs_per_match") AS "average_player_runs_per_match"
    FROM player_avg pa
    JOIN "player" p
      ON pa."player_id" = p."player_id"
    GROUP BY p."country_name"
)
SELECT
    "country",
    ROUND("average_player_runs_per_match", 4) AS "average_player_runs_per_match"
FROM country_avg
ORDER BY "average_player_runs_per_match" DESC, "country"
LIMIT 5;