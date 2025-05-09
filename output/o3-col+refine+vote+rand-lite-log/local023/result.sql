WITH season5_matches AS (
    SELECT match_id
    FROM match
    WHERE season_id = 5
),
player_runs AS (
    SELECT bb.striker                         AS player_id,
           SUM(bs.runs_scored)                AS total_runs
    FROM ball_by_ball   AS bb
    JOIN batsman_scored AS bs
         ON  bs.match_id   = bb.match_id
         AND bs.over_id    = bb.over_id
         AND bs.ball_id    = bb.ball_id
         AND bs.innings_no = bb.innings_no
    WHERE bb.match_id IN (SELECT match_id FROM season5_matches)
    GROUP BY bb.striker
),
player_matches AS (
    SELECT pm.player_id,
           COUNT(DISTINCT pm.match_id)        AS matches_played
    FROM player_match AS pm
    WHERE pm.match_id IN (SELECT match_id FROM season5_matches)
    GROUP BY pm.player_id
)
SELECT p.player_name,
       ROUND(1.0 * pr.total_runs / pm.matches_played, 4) AS batting_average
FROM player_runs    AS pr
JOIN player_matches AS pm ON pm.player_id = pr.player_id
JOIN player         AS p  ON p.player_id  = pr.player_id
ORDER BY batting_average DESC
LIMIT 5;