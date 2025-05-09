WITH player_match_runs AS (
    /* Runs scored by each player in every match */
    SELECT
        bb.match_id,
        bb.striker       AS player_id,
        SUM(bs.runs_scored) AS runs_in_match
    FROM ball_by_ball      AS bb
    JOIN batsman_scored    AS bs
      ON  bb.match_id  = bs.match_id
      AND bb.over_id   = bs.over_id
      AND bb.ball_id   = bs.ball_id
      AND bb.innings_no = bs.innings_no
    GROUP BY
        bb.match_id,
        bb.striker
),
player_avg AS (
    /* Average runs per match for every player */
    SELECT
        player_id,
        AVG(runs_in_match) AS avg_runs_per_match
    FROM player_match_runs
    GROUP BY player_id
)
SELECT
    p.country_name,
    ROUND(AVG(pa.avg_runs_per_match), 4) AS country_batting_average
FROM player_avg AS pa
JOIN player     AS p
  ON p.player_id = pa.player_id
GROUP BY p.country_name
ORDER BY country_batting_average DESC,
         p.country_name ASC
LIMIT 5;