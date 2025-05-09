WITH season5_matches AS (
    SELECT match_id
    FROM match
    WHERE season_id = 5
),
runs AS (
    SELECT bb.striker AS player_id,
           SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball AS bb
    JOIN batsman_scored AS bs
         ON bb.match_id = bs.match_id
        AND bb.over_id  = bs.over_id
        AND bb.ball_id  = bs.ball_id
    WHERE bb.match_id IN (SELECT match_id FROM season5_matches)
    GROUP BY bb.striker
),
matches AS (
    SELECT pm.player_id,
           COUNT(DISTINCT pm.match_id) AS matches_played
    FROM player_match AS pm
    WHERE pm.match_id IN (SELECT match_id FROM season5_matches)
    GROUP BY pm.player_id
),
averages AS (
    SELECT r.player_id,
           ROUND(1.0 * r.total_runs / m.matches_played, 4) AS batting_average
    FROM runs     AS r
    JOIN matches  AS m ON r.player_id = m.player_id
)
SELECT p.player_name,
       a.batting_average
FROM averages AS a
JOIN player   AS p ON p.player_id = a.player_id
ORDER BY a.batting_average DESC,
         p.player_name
LIMIT 5;