/* Average of the total runs scored by every batsman (striker) 
   who has scored more than 50 runs in a single match */
SELECT 
    AVG("total_runs") AS "average_total_runs"
FROM (
    SELECT 
        bb."match_id",
        bb."striker"          AS "player_id",
        SUM(bs."runs_scored") AS "total_runs"
    FROM IPL.IPL.BALL_BY_BALL  bb
    JOIN IPL.IPL.BATSMAN_SCORED bs
         ON  bb."match_id"   = bs."match_id"
        AND bb."innings_no"  = bs."innings_no"
        AND bb."over_id"     = bs."over_id"
        AND bb."ball_id"     = bs."ball_id"
    GROUP BY 
        bb."match_id",
        bb."striker"
    HAVING 
        SUM(bs."runs_scored") > 50
) AS per_player_match_totals;