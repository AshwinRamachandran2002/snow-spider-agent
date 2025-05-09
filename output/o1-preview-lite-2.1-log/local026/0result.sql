SELECT
    p."player_name" AS Bowler_Name,
    ROUND(SUM(
        COALESCE(s."runs_scored", 0) +
        CASE
            WHEN e."extra_type" IN ('wides', 'noballs') THEN e."extra_runs"
            ELSE 0
        END
    ), 4) AS Total_Runs_Conceded_In_Over,
    b."match_id" AS Match_ID,
    b."over_id" AS Over_ID
FROM
    "ball_by_ball" b
LEFT JOIN
    "batsman_scored" s ON b."match_id" = s."match_id"
    AND b."innings_no" = s."innings_no"
    AND b."over_id" = s."over_id"
    AND b."ball_id" = s."ball_id"
LEFT JOIN
    "extra_runs" e ON b."match_id" = e."match_id"
    AND b."innings_no" = e."innings_no"
    AND b."over_id" = e."over_id"
    AND b."ball_id" = e."ball_id"
JOIN
    "player" p ON b."bowler" = p."player_id"
GROUP BY
    b."match_id", b."over_id", b."bowler"
ORDER BY
    Total_Runs_Conceded_In_Over DESC
LIMIT 3;