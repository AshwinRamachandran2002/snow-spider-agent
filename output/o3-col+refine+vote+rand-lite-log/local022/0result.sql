WITH hundred_plus AS (
    SELECT 
        b.match_id,
        b.striker          AS player_id,
        pm.team_id,
        SUM(ba.runs_scored) AS total_runs
    FROM ball_by_ball   AS b
    JOIN batsman_scored AS ba
      ON b.match_id   = ba.match_id
     AND b.over_id    = ba.over_id
     AND b.ball_id    = ba.ball_id
     AND b.innings_no = ba.innings_no
    JOIN player_match  AS pm
      ON pm.match_id  = b.match_id
     AND pm.player_id = b.striker
    GROUP BY b.match_id, b.striker, pm.team_id
    HAVING total_runs >= 100
)

SELECT DISTINCT p.player_name
FROM hundred_plus AS hp
JOIN match   AS m ON m.match_id  = hp.match_id
JOIN player  AS p ON p.player_id = hp.player_id
WHERE hp.team_id <> m.match_winner;