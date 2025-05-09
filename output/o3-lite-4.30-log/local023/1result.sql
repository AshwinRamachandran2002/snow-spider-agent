WITH season5_match_ids AS (
    SELECT match_id
    FROM match
    WHERE season_id = 5
),
player_season5_stats AS (
    SELECT
        b.striker                       AS player_id,
        SUM(bs.runs_scored)             AS total_runs,
        COUNT(DISTINCT b.match_id)      AS matches_played
    FROM ball_by_ball b
    JOIN batsman_scored bs
         ON  b.match_id   = bs.match_id
         AND b.over_id    = bs.over_id
         AND b.ball_id    = bs.ball_id
         AND b.innings_no = bs.innings_no
    WHERE b.match_id IN (SELECT match_id FROM season5_match_ids)
    GROUP BY b.striker
),
player_avg AS (
    SELECT
        player_id,
        total_runs * 1.0 / matches_played AS batting_average
    FROM player_season5_stats
)
SELECT
    p.player_name,
    ROUND(pa.batting_average, 4) AS batting_average
FROM player_avg pa
JOIN player p ON p.player_id = pa.player_id
ORDER BY pa.batting_average DESC,
         p.player_name
LIMIT 5;