WITH player_runs AS (
    SELECT
        b.match_id,
        b.striker            AS player_id,
        SUM(bs.runs_scored)  AS total_runs
    FROM batsman_scored AS bs
    JOIN ball_by_ball  AS b
         ON bs.match_id   = b.match_id
        AND bs.over_id    = b.over_id
        AND bs.ball_id    = b.ball_id
        AND bs.innings_no = b.innings_no
    GROUP BY b.match_id, b.striker
),
centuries_for_losing_team AS (
    SELECT DISTINCT pr.player_id
    FROM player_runs  AS pr
    JOIN player_match AS pm ON pr.match_id = pm.match_id
                            AND pr.player_id = pm.player_id
    JOIN "match"      AS m  ON pr.match_id = m.match_id
    WHERE pr.total_runs >= 100        -- scored at least 100
      AND m.match_winner IS NOT NULL  -- match had a winner
      AND pm.team_id <> m.match_winner -- player's team lost
)
SELECT DISTINCT p.player_name
FROM centuries_for_losing_team AS c
JOIN player AS p ON c.player_id = p.player_id
ORDER BY p.player_name;