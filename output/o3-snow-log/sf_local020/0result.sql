WITH deliveries AS (
    SELECT
        b."bowler",
        COALESCE(bs."runs_scored", 0)                                        AS runs_off_bat,
        COALESCE(
            CASE 
                WHEN er."extra_type" IN ('wides', 'noballs', 'penalty') 
                THEN er."extra_runs" 
            END, 
        0)                                                                  AS extras_conceded
    FROM IPL.IPL."BALL_BY_BALL" b
    LEFT JOIN IPL.IPL."BATSMAN_SCORED" bs
           ON  b."match_id"  = bs."match_id"
           AND b."innings_no"= bs."innings_no"
           AND b."over_id"   = bs."over_id"
           AND b."ball_id"   = bs."ball_id"
    LEFT JOIN IPL.IPL."EXTRA_RUNS" er
           ON  b."match_id"  = er."match_id"
           AND b."innings_no"= er."innings_no"
           AND b."over_id"   = er."over_id"
           AND b."ball_id"   = er."ball_id"
), 
bowler_runs AS (
    SELECT
        "bowler",
        SUM(runs_off_bat + extras_conceded) AS runs_conceded
    FROM deliveries
    GROUP BY "bowler"
), 
bowler_wickets AS (
    SELECT
        b."bowler",
        COUNT(*) AS wickets
    FROM IPL.IPL."WICKET_TAKEN" w
    JOIN IPL.IPL."BALL_BY_BALL" b
         ON b."match_id"   = w."match_id"
        AND b."innings_no" = w."innings_no"
        AND b."over_id"    = w."over_id"
        AND b."ball_id"    = w."ball_id"
    WHERE w."kind_out" NOT IN ('run out', 'retired hurt')
    GROUP BY b."bowler"
), 
bowling_average AS (
    SELECT
        r."bowler",
        r.runs_conceded,
        w.wickets,
        r.runs_conceded / w.wickets AS avg_per_wicket
    FROM bowler_runs    r
    JOIN bowler_wickets w
      ON r."bowler" = w."bowler"
    WHERE w.wickets > 0
)
SELECT
    p."player_name" AS bowler_name,
    ROUND(b.avg_per_wicket, 4) AS bowling_average
FROM bowling_average b
JOIN IPL.IPL."PLAYER" p
  ON b."bowler" = p."player_id"
ORDER BY b.avg_per_wicket ASC NULLS LAST
LIMIT 1;