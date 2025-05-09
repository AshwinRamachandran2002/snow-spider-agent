WITH player_matches AS (
    SELECT 
        player_id, 
        COUNT(DISTINCT match_id) AS matches_played
    FROM player_match
    GROUP BY player_id
),
player_runs AS (
    SELECT 
        b.striker AS player_id,
        SUM(s.runs_scored) AS total_runs
    FROM ball_by_ball b
    JOIN batsman_scored s
      ON s.match_id  = b.match_id
     AND s.over_id   = b.over_id
     AND s.ball_id   = b.ball_id
     AND s.innings_no = b.innings_no
    GROUP BY b.striker
),
player_avg AS (
    SELECT
        p.player_id,
        COALESCE(r.total_runs, 0) * 1.0 / pm.matches_played AS avg_runs_per_match
    FROM player p
    JOIN player_matches pm ON pm.player_id = p.player_id
    LEFT JOIN player_runs  r ON r.player_id = p.player_id
),
country_avg AS (
    SELECT
        pl.country_name,
        AVG(pa.avg_runs_per_match) AS country_batting_avg
    FROM player           pl
    JOIN player_avg       pa ON pa.player_id = pl.player_id
    GROUP BY pl.country_name
)
SELECT
    country_name,
    ROUND(country_batting_avg, 4) AS country_batting_avg
FROM country_avg
ORDER BY country_batting_avg DESC, country_name
LIMIT 5;