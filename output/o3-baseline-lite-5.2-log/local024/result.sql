WITH player_runs AS (
    /* total runs scored by every player across all matches */
    SELECT 
        bb.striker           AS player_id,
        SUM(bs.runs_scored)  AS total_runs
    FROM batsman_scored AS bs
    JOIN ball_by_ball  AS bb
         ON  bs.match_id   = bb.match_id
         AND bs.over_id    = bb.over_id
         AND bs.ball_id    = bb.ball_id
         AND bs.innings_no = bb.innings_no
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
    /* individual player batting average (runs per match) */
    SELECT
        pm.player_id,
        CAST(COALESCE(pr.total_runs,0) AS FLOAT) / pm.matches_played AS avg_runs_per_match
    FROM player_matches pm
    LEFT JOIN player_runs pr
           ON pm.player_id = pr.player_id
    WHERE pm.matches_played > 0
),
country_avg AS (
    /* average of player averages for every country */
    SELECT
        p.country_name,
        AVG(pa.avg_runs_per_match) AS country_batting_average
    FROM player_avg pa
    JOIN player p
         ON pa.player_id = p.player_id
    GROUP BY p.country_name
)
SELECT
    country_name,
    ROUND(country_batting_average,4) AS country_batting_average
FROM country_avg
ORDER BY country_batting_average DESC, country_name
LIMIT 5;