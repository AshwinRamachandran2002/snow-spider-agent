SELECT 
    country_name,
    ROUND(AVG(player_avg), 4) AS country_batting_avg
FROM (
        /* --- player-level average runs per match --- */
        SELECT 
            p.country_name,
            CAST(SUM(bs.runs_scored) AS FLOAT) / COUNT(DISTINCT b.match_id) AS player_avg
        FROM ball_by_ball  AS b
        JOIN batsman_scored AS bs
              ON bs.match_id   = b.match_id
             AND bs.over_id    = b.over_id
             AND bs.ball_id    = b.ball_id
             AND bs.innings_no = b.innings_no
        JOIN player AS p
              ON p.player_id = b.striker
        GROUP BY p.player_id
) AS player_avgs
GROUP BY country_name
ORDER BY country_batting_avg DESC
LIMIT 5;