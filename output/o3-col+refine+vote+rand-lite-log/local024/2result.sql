WITH run_total AS (
    SELECT 
        b.striker AS player_id,
        SUM(s.runs_scored) AS total_runs
    FROM ball_by_ball AS b
    JOIN batsman_scored AS s
      ON b.match_id   = s.match_id
     AND b.over_id    = s.over_id
     AND b.ball_id    = s.ball_id
     AND b.innings_no = s.innings_no
    GROUP BY b.striker
),
match_cnt AS (
    SELECT 
        player_id,
        COUNT(DISTINCT match_id) AS matches_played
    FROM player_match
    GROUP BY player_id
),
player_avg AS (
    SELECT 
        r.player_id,
        1.0 * r.total_runs / m.matches_played AS avg_runs_per_match
    FROM run_total AS r
    JOIN match_cnt AS m
      ON r.player_id = m.player_id
)
SELECT 
    p.country_name,
    ROUND(AVG(pa.avg_runs_per_match), 4) AS country_batting_avg
FROM player_avg AS pa
JOIN player     AS p
  ON pa.player_id = p.player_id
GROUP BY p.country_name
ORDER BY country_batting_avg DESC
LIMIT 5;