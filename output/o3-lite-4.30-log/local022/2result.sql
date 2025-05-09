WITH player_runs AS (
    SELECT
        b.match_id,
        bb.striker AS player_id,
        SUM(b.runs_scored) AS total_runs
    FROM batsman_scored AS b
    JOIN ball_by_ball AS bb
      ON b.match_id  = bb.match_id
     AND b.over_id   = bb.over_id
     AND b.ball_id   = bb.ball_id
     AND b.innings_no = bb.innings_no
    GROUP BY b.match_id, bb.striker
),
centuries AS (
    SELECT *
    FROM player_runs
    WHERE total_runs >= 100
)
SELECT DISTINCT
    p.player_name
FROM centuries AS c
JOIN player_match AS pm
  ON pm.match_id = c.match_id
 AND pm.player_id = c.player_id
JOIN match AS m
  ON m.match_id = c.match_id
JOIN player AS p
  ON p.player_id = c.player_id
WHERE pm.team_id <> m.match_winner;