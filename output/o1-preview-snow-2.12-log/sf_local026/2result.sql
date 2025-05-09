SELECT
    p."player_name" AS "bowler_name",
    b."match_id",
    SUM(COALESCE(s."runs_scored", 0) + COALESCE(e."extra_runs", 0)) AS "runs_conceded_in_one_over"
FROM
    IPL.IPL.BALL_BY_BALL b
    LEFT JOIN IPL.IPL.BATSMAN_SCORED s ON
        b."match_id" = s."match_id"
        AND b."over_id" = s."over_id"
        AND b."ball_id" = s."ball_id"
        AND b."innings_no" = s."innings_no"
    LEFT JOIN IPL.IPL.EXTRA_RUNS e ON
        b."match_id" = e."match_id"
        AND b."over_id" = e."over_id"
        AND b."ball_id" = e."ball_id"
        AND b."innings_no" = e."innings_no"
    JOIN IPL.IPL.PLAYER p ON
        b."bowler" = p."player_id"
GROUP BY
    p."player_name",
    b."match_id",
    b."over_id"
ORDER BY
    "runs_conceded_in_one_over" DESC NULLS LAST
LIMIT 3;