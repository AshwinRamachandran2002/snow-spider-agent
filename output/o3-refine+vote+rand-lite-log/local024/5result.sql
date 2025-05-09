WITH player_runs AS (
    /* total runs scored by each batsman across all matches */
    SELECT 
        bb.striker                       AS player_id,
        SUM(bs.runs_scored)              AS total_runs
    FROM batsman_scored  bs
    JOIN ball_by_ball    bb
         ON  bb.match_id   = bs.match_id
         AND bb.over_id    = bs.over_id
         AND bb.ball_id    = bs.ball_id
         AND bb.innings_no = bs.innings_no
    GROUP BY bb.striker
),
player_matches AS (
    /* number of matches each player appeared in */
    SELECT 
        player_id,
        COUNT(DISTINCT match_id) AS matches_played
    FROM player_match
    GROUP BY player_id
),
player_avg AS (
    /* individual batting average: runs per match for every player */
    SELECT 
        pl.player_id,
        COALESCE(pr.total_runs,0)                     AS total_runs,
        pm.matches_played,
        (COALESCE(pr.total_runs,0) * 1.0) / pm.matches_played  AS avg_runs_per_match,
        pl.country_name
    FROM player          pl
    JOIN player_matches  pm  ON pm.player_id = pl.player_id
    LEFT JOIN player_runs pr ON pr.player_id = pl.player_id
)
SELECT 
    country_name,
    ROUND(AVG(avg_runs_per_match),4) AS country_batting_avg
FROM player_avg
GROUP BY country_name
ORDER BY country_batting_avg DESC, country_name
LIMIT 5;