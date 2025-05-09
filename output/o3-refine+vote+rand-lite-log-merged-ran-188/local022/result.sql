WITH player_runs AS (
    -- total runs each batsman scored in every match and the team he was batting for
    SELECT
        bb.match_id,
        bb.striker            AS player_id,
        bb.team_batting       AS team_id,
        SUM(bs.runs_scored)   AS total_runs
    FROM ball_by_ball  AS bb
    JOIN batsman_scored AS bs
         ON  bb.match_id = bs.match_id
         AND bb.over_id  = bs.over_id
         AND bb.ball_id  = bs.ball_id
         AND bb.innings_no = bs.innings_no
    GROUP BY bb.match_id, bb.striker, bb.team_batting
),
centuries_in_losses AS (
    -- keep only centuries made for the side that eventually lost
    SELECT pr.*
    FROM player_runs pr
    JOIN match m
         ON m.match_id = pr.match_id
    WHERE pr.total_runs >= 100               -- century
      AND m.match_winner IS NOT NULL         -- result decided
      AND m.match_winner <> pr.team_id       -- player’s team lost
)
SELECT DISTINCT p.player_name
FROM centuries_in_losses cil
JOIN player p ON p.player_id = cil.player_id
ORDER BY p.player_name;