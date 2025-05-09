WITH player_matches AS (
    -- how many matches each player appeared in
    SELECT 
        player_id,
        COUNT(DISTINCT match_id) AS matches_played
    FROM player_match
    GROUP BY player_id
),
player_runs AS (
    -- total runs each player scored across all matches
    SELECT 
        bbb.striker AS player_id,
        SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball AS bbb
    JOIN batsman_scored AS bs
      ON bbb.match_id = bs.match_id
     AND bbb.over_id  = bs.over_id
     AND bbb.ball_id  = bs.ball_id
    GROUP BY bbb.striker
),
player_stats AS (
    -- individual batting average (runs per match) for every player
    SELECT
        pm.player_id,
        pm.matches_played,
        COALESCE(pr.total_runs, 0) AS total_runs,
        COALESCE(pr.total_runs, 0) * 1.0 / pm.matches_played AS avg_runs_per_match
    FROM player_matches AS pm
    LEFT JOIN player_runs AS pr
      ON pm.player_id = pr.player_id
),
country_stats AS (
    -- country‑level average of the players’ batting averages
    SELECT
        pl.country_name,
        AVG(ps.avg_runs_per_match) AS country_batting_avg
    FROM player_stats AS ps
    JOIN player AS pl
      ON ps.player_id = pl.player_id
    GROUP BY pl.country_name
)
SELECT
    country_name,
    country_batting_avg
FROM country_stats
ORDER BY country_batting_avg DESC,
         country_name
LIMIT 5;