-- Task: Retrieve the names of players who scored no less than 100 runs in a match.
WITH PLAYER_RUNS AS (
    SELECT 
        BBB."striker" AS "player_id", 
        BBB."match_id", 
        SUM(CAST(BSC."runs_scored" AS DOUBLE)) AS "total_runs"
    FROM 
        IPL.IPL.BALL_BY_BALL AS BBB
    JOIN 
        IPL.IPL.BATSMAN_SCORED AS BSC
    ON 
        BBB."match_id" = BSC."match_id" 
        AND BBB."over_id" = BSC."over_id" 
        AND BBB."ball_id" = BSC."ball_id" 
        AND BBB."innings_no" = BSC."innings_no"
    GROUP BY 
        BBB."striker", BBB."match_id"
    HAVING 
        SUM(CAST(BSC."runs_scored" AS DOUBLE)) >= 100
)
SELECT DISTINCT 
    P."player_name" 
FROM 
    PLAYER_RUNS AS PR
JOIN 
    IPL.IPL.PLAYER AS P
ON 
    P."player_id" = PR."player_id"
ORDER BY 
    P."player_name";