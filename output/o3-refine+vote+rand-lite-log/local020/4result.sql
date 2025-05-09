WITH delivery_runs AS (
    /* runs conceded by every bowler for every legal ball */
    SELECT  b."bowler",
            COALESCE(bs."runs_scored",0) + COALESCE(er."extra_runs",0) AS runs_conceded
    FROM    "ball_by_ball" b
    LEFT JOIN "batsman_scored" bs
           ON bs."match_id"  = b."match_id"
          AND bs."over_id"   = b."over_id"
          AND bs."ball_id"   = b."ball_id"
          AND bs."innings_no"= b."innings_no"
    LEFT JOIN "extra_runs" er
           ON er."match_id"  = b."match_id"
          AND er."over_id"   = b."over_id"
          AND er."ball_id"   = b."ball_id"
          AND er."innings_no"= b."innings_no"
),
bowler_runs AS (
    SELECT  "bowler",
            SUM(runs_conceded) AS total_runs
    FROM    delivery_runs
    GROUP BY "bowler"
),
bowler_wkts AS (
    /* wickets that are credited to the bowler (exclude run‑outs, etc.) */
    SELECT  b."bowler",
            COUNT(*) AS wickets
    FROM    "wicket_taken" w
    JOIN    "ball_by_ball" b
          ON b."match_id"   = w."match_id"
         AND b."over_id"    = w."over_id"
         AND b."ball_id"    = w."ball_id"
         AND b."innings_no" = w."innings_no"
    WHERE   LOWER(w."kind_out") NOT IN ('run out','retired hurt','retired','obstructing the field')
    GROUP BY b."bowler"
),
bowling_avg AS (
    SELECT  r."bowler",
            1.0 * r.total_runs / w.wickets AS avg_per_wicket
    FROM    bowler_runs  r
    JOIN    bowler_wkts w
           ON r."bowler" = w."bowler"
)
SELECT  p."player_name"
FROM    bowling_avg ba
JOIN    "player" p
       ON p."player_id" = ba."bowler"
ORDER BY ba.avg_per_wicket ASC, p."player_name"
LIMIT 1;