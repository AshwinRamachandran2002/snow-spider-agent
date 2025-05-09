WITH over_totals AS (
    SELECT  b."match_id",
            b."over_id",
            b."bowler",
            SUM( COALESCE(bs."runs_scored",0) + COALESCE(er."extra_runs",0) ) AS "over_runs"
    FROM          "ball_by_ball"  AS b
    LEFT JOIN     "batsman_scored" AS bs
           ON b."match_id" = bs."match_id"
          AND b."over_id"  = bs."over_id"
          AND b."ball_id"  = bs."ball_id"
    LEFT JOIN     "extra_runs"     AS er
           ON b."match_id" = er."match_id"
          AND b."over_id"  = er."over_id"
          AND b."ball_id"  = er."ball_id"
    GROUP BY b."match_id", b."over_id", b."bowler"
),
max_per_match AS (
    SELECT  "match_id",
            MAX("over_runs") AS "max_runs"
    FROM    over_totals
    GROUP BY "match_id"
),
max_overs AS (
    SELECT  ot.*
    FROM    over_totals AS ot
    JOIN    max_per_match AS mm
           ON ot."match_id" = mm."match_id"
          AND ot."over_runs" = mm."max_runs"
)
SELECT      p."player_name"               AS "bowler_name",
            mo."match_id",
            mo."over_runs"                AS "runs_conceded"
FROM        max_overs  AS mo
JOIN        "player"   AS p
       ON   p."player_id" = mo."bowler"
ORDER BY    mo."over_runs" DESC
LIMIT 3;