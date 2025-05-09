WITH season5_matches AS (
    SELECT "match_id"
    FROM IPL.IPL."MATCH"
    WHERE "season_id" = 5
),
player_runs AS (                  -- runs each batsman scored in every season-5 match
    SELECT
        bb."striker"  AS player_id,
        bs."match_id",
        SUM(bs."runs_scored") AS runs_in_match
    FROM IPL.IPL.BALL_BY_BALL   bb
    JOIN IPL.IPL.BATSMAN_SCORED bs
      ON  bb."match_id" = bs."match_id"
      AND bb."over_id"  = bs."over_id"
      AND bb."ball_id"  = bs."ball_id"
      AND bb."innings_no" = bs."innings_no"
    JOIN season5_matches sm
      ON bb."match_id" = sm."match_id"
    GROUP BY bb."striker", bs."match_id"
),
total_runs AS (                   -- total runs per player in season 5
    SELECT
        player_id,
        SUM(runs_in_match) AS total_runs
    FROM player_runs
    GROUP BY player_id
),
matches_played AS (               -- number of season-5 matches each player appeared in
    SELECT
        pm."player_id",
        COUNT(DISTINCT pm."match_id") AS matches_played
    FROM IPL.IPL.PLAYER_MATCH pm
    JOIN season5_matches sm
      ON pm."match_id" = sm."match_id"
    GROUP BY pm."player_id"
),
player_avg AS (                   -- batting average (runs per match)
    SELECT
        tr.player_id,
        ROUND(tr.total_runs / mp.matches_played, 4) AS batting_average
    FROM total_runs     tr
    JOIN matches_played mp
      ON tr.player_id = mp."player_id"
    WHERE mp.matches_played > 0
)
SELECT
    pl."player_name",
    pa.batting_average
FROM player_avg             pa
JOIN IPL.IPL.PLAYER         pl
  ON pa.player_id = pl."player_id"
ORDER BY pa.batting_average DESC NULLS LAST
LIMIT 5;