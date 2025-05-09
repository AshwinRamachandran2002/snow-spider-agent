WITH player_runs AS (
    SELECT
        bb.match_id,
        bb.striker          AS player_id,
        SUM(bs.runs_scored) AS total_runs,
        pm.team_id          AS player_team
    FROM ball_by_ball   AS bb
    JOIN batsman_scored AS bs
         ON  bb.match_id   = bs.match_id
         AND bb.over_id    = bs.over_id
         AND bb.ball_id    = bs.ball_id
         AND bb.innings_no = bs.innings_no
    JOIN player_match   AS pm
         ON  pm.match_id = bb.match_id
         AND pm.player_id = bb.striker
    GROUP BY bb.match_id, bb.striker
)
SELECT DISTINCT pl.player_name
FROM player_runs pr
JOIN match  AS m  ON m.match_id  = pr.match_id
JOIN player AS pl ON pl.player_id = pr.player_id
WHERE pr.total_runs >= 100
  AND m.match_winner IS NOT NULL          -- ensure the match had a winner
  AND pr.player_team <> m.match_winner;   -- player’s team lost