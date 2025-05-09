WITH runs AS (
    SELECT 
        b.match_id,
        b.striker        AS player_id,
        b.team_batting   AS team_id,
        SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball AS b
    JOIN batsman_scored AS bs
         ON b.match_id = bs.match_id
        AND b.over_id  = bs.over_id
        AND b.ball_id  = bs.ball_id
    GROUP BY b.match_id, b.striker, b.team_batting
    HAVING total_runs >= 100
),
losers AS (
    SELECT 
        m.match_id,
        CASE 
            WHEN m.team_1 = m.match_winner THEN m.team_2
            ELSE m.team_1
        END AS loser_team_id
    FROM match AS m
    WHERE m.match_winner IS NOT NULL
),
qualifying_innings AS (
    SELECT r.player_id
    FROM runs   AS r
    JOIN losers AS l
      ON r.match_id = l.match_id
     AND r.team_id  = l.loser_team_id
)
SELECT DISTINCT p.player_name
FROM player AS p
JOIN qualifying_innings AS q
  ON p.player_id = q.player_id;