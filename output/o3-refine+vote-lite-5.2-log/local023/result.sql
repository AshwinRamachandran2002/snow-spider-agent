WITH season_matches AS (
    SELECT match_id
    FROM match
    WHERE season_id = 5
),
player_runs_per_match AS (
    SELECT 
        bb.striker AS player_id,
        bs.match_id,
        SUM(bs.runs_scored) AS runs_in_match
    FROM batsman_scored AS bs
    JOIN ball_by_ball AS bb
         ON bs.match_id   = bb.match_id
        AND bs.over_id    = bb.over_id
        AND bs.ball_id    = bb.ball_id
        AND bs.innings_no = bb.innings_no
    WHERE bs.match_id IN (SELECT match_id FROM season_matches)
    GROUP BY bb.striker, bs.match_id
),
player_avg AS (
    SELECT 
        player_id,
        AVG(runs_in_match) AS avg_runs
    FROM player_runs_per_match
    GROUP BY player_id
)
SELECT 
    p.player_name,
    ROUND(pa.avg_runs, 4) AS batting_average
FROM player_avg AS pa
JOIN player AS p
     ON p.player_id = pa.player_id
ORDER BY pa.avg_runs DESC, p.player_name ASC
LIMIT 5;