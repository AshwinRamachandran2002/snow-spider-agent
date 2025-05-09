SELECT DISTINCT P."player_name" AS striker_name
FROM IPL.IPL.PLAYER P
JOIN (
    SELECT B."striker", B."match_id", SUM(S."runs_scored") AS total_runs, B."team_batting"
    FROM IPL.IPL.BALL_BY_BALL B
    JOIN IPL.IPL.BATSMAN_SCORED S
        ON B."match_id" = S."match_id"
        AND B."over_id" = S."over_id"
        AND B."ball_id" = S."ball_id"
        AND B."innings_no" = S."innings_no"
    GROUP BY B."match_id", B."striker", B."team_batting"
    HAVING SUM(S."runs_scored") >= 100
) T
ON P."player_id" = T."striker"
JOIN IPL.IPL.MATCH M
    ON T."match_id" = M."match_id"
WHERE T."team_batting" != M."match_winner";