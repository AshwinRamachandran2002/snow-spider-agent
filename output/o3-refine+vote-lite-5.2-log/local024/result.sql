WITH player_matches AS (
    -- every match a player appeared in
    SELECT DISTINCT player_id, match_id
    FROM player_match
),
player_runs AS (
    -- total runs a batsman scored in a match
    SELECT bb.striker          AS player_id,
           bb.match_id,
           SUM(bs.runs_scored) AS runs
    FROM batsman_scored bs
    JOIN ball_by_ball bb
      ON bb.match_id  = bs.match_id
     AND bb.over_id   = bs.over_id
     AND bb.ball_id   = bs.ball_id
     AND bb.innings_no = bs.innings_no
    GROUP BY bb.match_id, bb.striker
),
player_match_runs AS (
    -- attach the run tally (0 if the player did not bat/score) to every
    -- match the player took part in
    SELECT pm.player_id,
           pm.match_id,
           COALESCE(pr.runs, 0) AS runs
    FROM player_matches pm
    LEFT JOIN player_runs pr
           ON pr.player_id = pm.player_id
          AND pr.match_id  = pm.match_id
),
player_average AS (
    -- individual batting average per match for every player
    SELECT player_id,
           CAST(SUM(runs) AS REAL) / COUNT(*) AS avg_runs_per_match
    FROM player_match_runs
    GROUP BY player_id
),
country_averages AS (
    -- average of players' averages for each country
    SELECT pl.country_name,
           AVG(pa.avg_runs_per_match) AS country_batting_average
    FROM player_average pa
    JOIN player pl ON pl.player_id = pa.player_id
    GROUP BY pl.country_name
)
SELECT country_name,
       ROUND(country_batting_average, 4) AS country_batting_average
FROM country_averages
ORDER BY country_batting_average DESC,
         country_name
LIMIT 5;