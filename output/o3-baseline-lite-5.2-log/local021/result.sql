WITH runs_per_match AS (
    SELECT
        bbb.match_id,
        bbb.striker AS player_id,
        SUM(bs.runs_scored) AS runs_in_match
    FROM ball_by_ball AS bbb
    JOIN batsman_scored AS bs
      ON bbb.match_id   = bs.match_id
     AND bbb.over_id    = bs.over_id
     AND bbb.ball_id    = bs.ball_id
     AND bbb.innings_no = bs.innings_no
    GROUP BY bbb.match_id, bbb.striker
),
qualified_players AS (
    SELECT DISTINCT player_id
    FROM runs_per_match
    WHERE runs_in_match > 50
),
total_runs_per_player AS (
    SELECT
        bbb.striker AS player_id,
        SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball AS bbb
    JOIN batsman_scored AS bs
      ON bbb.match_id   = bs.match_id
     AND bbb.over_id    = bs.over_id
     AND bbb.ball_id    = bs.ball_id
     AND bbb.innings_no = bs.innings_no
    GROUP BY bbb.striker
)
SELECT ROUND(AVG(total_runs), 4) AS average_total_runs
FROM total_runs_per_player
WHERE player_id IN (SELECT player_id FROM qualified_players);