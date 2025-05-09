WITH player_runs AS (
    /* Runs scored by every batsman in every match */
    SELECT
        b.match_id,
        b.striker        AS player_id,
        pm.team_id,                      -- team he represents in that match
        SUM(s.runs_scored) AS runs_made
    FROM ball_by_ball   b
    JOIN batsman_scored s
         ON  s.match_id = b.match_id
         AND s.over_id  = b.over_id
         AND s.ball_id  = b.ball_id
         AND s.innings_no = b.innings_no
    JOIN player_match   pm
         ON  pm.match_id = b.match_id
         AND pm.player_id = b.striker
    GROUP BY b.match_id, b.striker
),
centuries_on_losing_side AS (
    /* Keep only 100+ scores where the player’s team lost */
    SELECT pr.*
    FROM   player_runs pr
    JOIN   match m
           ON m.match_id = pr.match_id
    WHERE  pr.runs_made >= 100
      AND  m.match_winner IS NOT NULL     -- result produced a winner
      AND  pr.team_id <> m.match_winner   -- player’s side lost
)
SELECT DISTINCT p.player_name
FROM   centuries_on_losing_side c
JOIN   player p
       ON p.player_id = c.player_id;