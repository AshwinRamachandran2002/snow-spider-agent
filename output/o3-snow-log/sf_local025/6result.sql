WITH bat AS (  -- runs scored off the bat in every over
    SELECT  "match_id",
            "innings_no",
            "over_id",
            SUM("runs_scored") AS "bat_runs"
    FROM IPL.IPL.BATSMAN_SCORED
    GROUP BY "match_id","innings_no","over_id"
),
ext AS (  -- extra-runs in every over
    SELECT  "match_id",
            "innings_no",
            "over_id",
            SUM("extra_runs") AS "extra_runs"
    FROM IPL.IPL.EXTRA_RUNS
    GROUP BY "match_id","innings_no","over_id"
),
comb AS ( -- combine bat + extras to get total runs in each over
    SELECT  COALESCE(b."match_id",e."match_id")     AS "match_id",
            COALESCE(b."innings_no",e."innings_no") AS "innings_no",
            COALESCE(b."over_id",e."over_id")       AS "over_id",
            COALESCE(b."bat_runs",0)
          + COALESCE(e."extra_runs",0)              AS "total_runs"
    FROM bat b
    FULL JOIN ext e
      ON b."match_id"   = e."match_id"
     AND b."innings_no" = e."innings_no"
     AND b."over_id"    = e."over_id"
),
ranked AS ( -- pick the single highest-scoring over of each match
    SELECT  comb.*,
            ROW_NUMBER() OVER (PARTITION BY "match_id"
                               ORDER BY "total_runs" DESC NULLS LAST,
                                        "innings_no",
                                        "over_id") AS "rn"
    FROM comb
),
top_over AS (
    SELECT *
    FROM ranked
    WHERE "rn" = 1      -- one row per match
),
over_bowler AS ( -- attach the bowler who delivered that over (first bowler id)
    SELECT  t."match_id",
            t."innings_no",
            t."over_id",
            t."total_runs",
            MIN(bbb."bowler") AS "bowler_id"
    FROM top_over t
    JOIN IPL.IPL.BALL_BY_BALL bbb
      ON t."match_id"   = bbb."match_id"
     AND t."innings_no" = bbb."innings_no"
     AND t."over_id"    = bbb."over_id"
    GROUP BY t."match_id",t."innings_no",t."over_id",t."total_runs"
),
with_name AS ( -- look up bowler name
    SELECT  ob.*,
            p."player_name" AS "bowler_name"
    FROM over_bowler ob
    LEFT JOIN IPL.IPL.PLAYER p
           ON ob."bowler_id" = p."player_id"
),
avg_calc AS ( -- overall average of those highest-scoring overs
    SELECT AVG("total_runs") AS "avg_highest_over_runs"
    FROM with_name
)
SELECT  wn."match_id",
        wn."innings_no",
        wn."over_id",
        wn."total_runs",
        wn."bowler_id",
        wn."bowler_name",
        ac."avg_highest_over_runs"
FROM with_name  wn
CROSS JOIN avg_calc ac
ORDER BY wn."match_id";