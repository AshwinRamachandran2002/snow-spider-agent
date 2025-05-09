WITH season_matches AS (
    SELECT match_id
    FROM match
    WHERE season_id = 5
),
player_runs AS (
    SELECT 
        bb.striker            AS player_id,
        SUM(bs.runs_scored)   AS total_runs
    FROM ball_by_ball  bb
    JOIN batsman_scored bs
         ON  bb.match_id   = bs.match_id
         AND bb.over_id    = bs.over_id
         AND bb.ball_id    = bs.ball_id
         AND bb.innings_no = bs.innings_no
    WHERE bb.match_id IN (SELECT match_id FROM season_matches)
    GROUP BY bb.striker
),
player_matches AS (
    SELECT 
        pm.player_id,
        COUNT(DISTINCT pm.match_id) AS matches_played
    FROM player_match pm
    WHERE pm.match_id IN (SELECT match_id FROM season_matches)
    GROUP BY pm.player_id
),
player_average AS (
    SELECT 
        p.player_name,
        ROUND(
            COALESCE(pr.total_runs, 0) * 1.0 / pm.matches_played,
            4
        ) AS batting_average
    FROM player_matches pm
    LEFT JOIN player_runs pr ON pr.player_id = pm.player_id
    JOIN player p            ON p.player_id = pm.player_id
)
SELECT 
    player_name,
    batting_average
FROM player_average
ORDER BY batting_average DESC, player_name
LIMIT 5;