WITH player_runs AS (
    SELECT 
        bs.match_id,
        bbb.striker              AS player_id,
        bbb.team_batting         AS team_id,
        SUM(bs.runs_scored)      AS total_runs
    FROM batsman_scored AS bs
    JOIN ball_by_ball AS bbb
         ON  bs.match_id   = bbb.match_id
         AND bs.over_id    = bbb.over_id
         AND bs.ball_id    = bbb.ball_id
         AND bs.innings_no = bbb.innings_no
    GROUP BY bs.match_id, bbb.striker, bbb.team_batting
    HAVING SUM(bs.runs_scored) >= 100        -- individual century
)

SELECT DISTINCT p.player_name
FROM player_runs   pr
JOIN match         m ON m.match_id  = pr.match_id
JOIN player        p ON p.player_id = pr.player_id
WHERE m.match_winner IS NOT NULL     -- match had a decisive result
  AND pr.team_id <> m.match_winner;  -- player’s team lost the match