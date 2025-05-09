WITH player_matches AS (
    SELECT player_id,
           COUNT(DISTINCT match_id) AS matches_played
    FROM   player_match
    GROUP  BY player_id
),
player_runs AS (
    SELECT b.striker AS player_id,
           SUM(bs.runs_scored) AS total_runs
    FROM   ball_by_ball  b
    JOIN   batsman_scored bs
           ON  b.match_id   = bs.match_id
          AND b.over_id    = bs.over_id
          AND b.ball_id    = bs.ball_id
          AND b.innings_no = bs.innings_no
    GROUP  BY b.striker
),
player_avg AS (
    SELECT pm.player_id,
           1.0 * COALESCE(pr.total_runs, 0) / pm.matches_played AS avg_runs_per_match
    FROM   player_matches pm
    LEFT JOIN player_runs pr
           ON pm.player_id = pr.player_id
)
SELECT p.country_name AS country,
       ROUND(AVG(pa.avg_runs_per_match), 4) AS average_player_runs_per_match
FROM   player_avg pa
JOIN   player p ON p.player_id = pa.player_id
GROUP  BY p.country_name
ORDER  BY average_player_runs_per_match DESC, country
LIMIT 5;