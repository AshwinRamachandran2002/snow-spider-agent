WITH runs_player_match AS (
    SELECT
        bb.match_id,
        bb.striker AS player_id,
        SUM(bs.runs_scored) AS runs_in_match
    FROM ball_by_ball AS bb
    JOIN batsman_scored AS bs
      ON bb.match_id   = bs.match_id
     AND bb.over_id    = bs.over_id
     AND bb.ball_id    = bs.ball_id
     AND bb.innings_no = bs.innings_no
    GROUP BY bb.match_id, bb.striker
),
player_avg AS (
    SELECT
        player_id,
        AVG(runs_in_match) AS avg_runs_per_match
    FROM runs_player_match
    GROUP BY player_id
),
country_avg AS (
    SELECT
        p.country_name,
        AVG(pa.avg_runs_per_match) AS country_batting_average
    FROM player_avg AS pa
    JOIN player     AS p
      ON pa.player_id = p.player_id
    GROUP BY p.country_name
)
SELECT
    country_name,
    ROUND(country_batting_average, 4) AS country_batting_average
FROM country_avg
ORDER BY country_batting_average DESC
LIMIT 5;