WITH season5_matches AS (
    SELECT match_id
    FROM "match"
    WHERE season_id = 5
),
total_runs AS (
    SELECT
        b.striker AS player_id,
        SUM(s.runs_scored) AS total_runs
    FROM ball_by_ball b
    JOIN batsman_scored s
      ON b.match_id   = s.match_id
     AND b.over_id    = s.over_id
     AND b.ball_id    = s.ball_id
     AND b.innings_no = s.innings_no
    WHERE b.match_id IN (SELECT match_id FROM season5_matches)
    GROUP BY b.striker
),
matches_played AS (
    SELECT
        player_id,
        COUNT(DISTINCT match_id) AS matches_played
    FROM player_match
    WHERE match_id IN (SELECT match_id FROM season5_matches)
    GROUP BY player_id
),
averages AS (
    SELECT
        tr.player_id,
        CAST(tr.total_runs AS FLOAT) / mp.matches_played AS avg_runs
    FROM total_runs tr
    JOIN matches_played mp ON mp.player_id = tr.player_id
)
SELECT
    p.player_name,
    ROUND(a.avg_runs, 4) AS batting_average
FROM averages a
JOIN player p ON p.player_id = a.player_id
ORDER BY a.avg_runs DESC
LIMIT 5;