WITH season_matches AS (
    SELECT match_id
    FROM match
    WHERE season_id = 5
),
/* total runs scored by every batsman in season‑5 */
runs_per_player AS (
    SELECT 
        bb.striker          AS player_id,
        SUM(bs.runs_scored) AS total_runs
    FROM season_matches sm
    JOIN batsman_scored bs
           ON sm.match_id = bs.match_id
    JOIN ball_by_ball bb
           ON bb.match_id   = bs.match_id
          AND bb.over_id    = bs.over_id
          AND bb.ball_id    = bs.ball_id
          AND bb.innings_no = bs.innings_no
    GROUP BY bb.striker
),
/* number of season‑5 matches in which every player appeared */
matches_per_player AS (
    SELECT 
        pm.player_id,
        COUNT(DISTINCT pm.match_id) AS matches_played
    FROM season_matches sm
    JOIN player_match pm
           ON sm.match_id = pm.match_id
    GROUP BY pm.player_id
),
player_average AS (
    SELECT 
        r.player_id,
        1.0 * r.total_runs / m.matches_played AS batting_average
    FROM runs_per_player r
    JOIN matches_per_player m
          ON m.player_id = r.player_id
)
SELECT
    p.player_name,
    ROUND(pa.batting_average, 4) AS batting_average
FROM player_average pa
JOIN player p
      ON p.player_id = pa.player_id
ORDER BY pa.batting_average DESC,
         p.player_name
LIMIT 5;