WITH runs_conceded AS (
    SELECT  b."bowler",
            SUM( COALESCE(bs."runs_scored",0) + COALESCE(er."extra_runs",0) ) AS total_runs
    FROM    "ball_by_ball"  b
    LEFT JOIN "batsman_scored" bs
           ON b."match_id"   = bs."match_id"
          AND b."over_id"    = bs."over_id"
          AND b."ball_id"    = bs."ball_id"
          AND b."innings_no" = bs."innings_no"
    LEFT JOIN "extra_runs"   er
           ON b."match_id"   = er."match_id"
          AND b."over_id"    = er."over_id"
          AND b."ball_id"    = er."ball_id"
          AND b."innings_no" = er."innings_no"
    GROUP BY b."bowler"
),
wickets_taken AS (
    SELECT  b."bowler",
            COUNT(*) AS wkts
    FROM    "ball_by_ball" b
    JOIN    "wicket_taken" w
           ON b."match_id"   = w."match_id"
          AND b."over_id"    = w."over_id"
          AND b."ball_id"    = w."ball_id"
          AND b."innings_no" = w."innings_no"
    WHERE   w."kind_out" <> 'run out'
    GROUP BY b."bowler"
)
SELECT  p."player_name",
        ROUND( CAST(r.total_runs AS FLOAT) / w.wkts , 2) AS bowling_average
FROM    runs_conceded r
JOIN    wickets_taken w ON r."bowler" = w."bowler"
JOIN    "player" p       ON p."player_id" = r."bowler"
WHERE   w.wkts > 0
ORDER BY bowling_average ASC, p."player_name"
LIMIT 1;