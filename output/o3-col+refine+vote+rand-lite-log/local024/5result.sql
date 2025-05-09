WITH player_runs AS (
    SELECT bb.striker AS player_id,
           SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball AS bb
    JOIN batsman_scored AS bs
      ON bb.match_id   = bs.match_id
     AND bb.over_id    = bs.over_id
     AND bb.ball_id    = bs.ball_id
     AND bb.innings_no = bs.innings_no
    GROUP BY bb.striker
),
player_matches AS (
    SELECT player_id,
           COUNT(DISTINCT match_id) AS matches_played
    FROM player_match
    GROUP BY player_id
),
player_average AS (
    SELECT pr.player_id,
           1.0 * pr.total_runs / pm.matches_played AS avg_runs_per_match
    FROM player_runs    AS pr
    JOIN player_matches AS pm
      ON pr.player_id = pm.player_id
),
country_average AS (
    SELECT p.country_name                                  AS country,
           ROUND(AVG(pa.avg_runs_per_match), 4)            AS country_batting_average
    FROM player          AS p
    JOIN player_average  AS pa
      ON p.player_id = pa.player_id
    GROUP BY p.country_name
)
SELECT country,
       country_batting_average
FROM country_average
ORDER BY country_batting_average DESC
LIMIT 5;