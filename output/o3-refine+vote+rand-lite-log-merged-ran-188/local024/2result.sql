WITH player_runs AS (           -- total runs scored by every player
    SELECT 
        bb.striker                            AS player_id,
        SUM(bs.runs_scored)                   AS total_runs
    FROM batsman_scored  bs
    JOIN ball_by_ball    bb
         ON bs.match_id = bb.match_id
        AND bs.over_id  = bb.over_id
        AND bs.ball_id  = bb.ball_id
    GROUP BY bb.striker
),
player_matches AS (            -- number of matches played by every player
    SELECT 
        player_id,
        COUNT(DISTINCT match_id)              AS matches_played
    FROM player_match
    GROUP BY player_id
),
player_avgs AS (               -- individual average runs per match for every player
    SELECT
        p.player_id,
        p.country_name,
        COALESCE(pr.total_runs,0)             AS total_runs,
        pm.matches_played,
        CASE 
            WHEN pm.matches_played > 0 
                 THEN COALESCE(pr.total_runs,0)*1.0 / pm.matches_played
            ELSE 0
        END                                    AS avg_runs_per_match
    FROM player           p
    JOIN player_matches   pm ON p.player_id = pm.player_id   -- keep only players who appeared in a match
    LEFT JOIN player_runs pr ON p.player_id = pr.player_id
)
SELECT
    country_name,
    ROUND(AVG(avg_runs_per_match),4)          AS country_batting_average
FROM player_avgs
GROUP BY country_name
ORDER BY country_batting_average DESC, country_name
LIMIT 5;