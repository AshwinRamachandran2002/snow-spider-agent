SELECT ROUND(AVG(total_runs), 4) AS "Average_total_score"
FROM (
    SELECT b."striker", SUM(bs."runs_scored") AS total_runs
    FROM IPL.IPL."BALL_BY_BALL" b
    JOIN IPL.IPL."BATSMAN_SCORED" bs
        ON b."match_id" = bs."match_id"
        AND b."over_id" = bs."over_id"
        AND b."ball_id" = bs."ball_id"
        AND b."innings_no" = bs."innings_no"
    GROUP BY b."striker"
    HAVING b."striker" IN (
        SELECT b2."striker"
        FROM IPL.IPL."BALL_BY_BALL" b2
        JOIN IPL.IPL."BATSMAN_SCORED" bs2
            ON b2."match_id" = bs2."match_id"
            AND b2."over_id" = bs2."over_id"
            AND b2."ball_id" = bs2."ball_id"
            AND b2."innings_no" = bs2."innings_no"
        GROUP BY b2."striker", b2."match_id"
        HAVING SUM(bs2."runs_scored") > 50
    )
) t;