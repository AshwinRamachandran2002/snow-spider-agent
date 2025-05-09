SELECT 
    p.player_name,
    ROUND(1.0 * t.total_runs / t.matches_played, 4) AS batting_average
FROM (
    SELECT 
        bb.striker            AS player_id,
        SUM(bs.runs_scored)   AS total_runs,
        COUNT(DISTINCT bb.match_id) AS matches_played
    FROM "ball_by_ball" bb
    JOIN "batsman_scored"  bs ON  bs.match_id  = bb.match_id
                             AND bs.over_id   = bb.over_id
                             AND bs.ball_id   = bb.ball_id
                             AND bs.innings_no = bb.innings_no
    JOIN "match" m            ON m.match_id = bb.match_id
    WHERE m.season_id = 5
    GROUP BY bb.striker
) t
JOIN "player" p ON p.player_id = t.player_id
ORDER BY batting_average DESC,
         p.player_name
LIMIT 5;