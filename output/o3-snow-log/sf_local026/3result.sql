WITH
/* runs off the bat per ball */
bat_runs AS (
    SELECT  "match_id",
            "innings_no",
            "over_id",
            "ball_id",
            SUM("runs_scored")      AS bat_runs
    FROM    IPL.IPL.BATSMAN_SCORED
    GROUP BY "match_id","innings_no","over_id","ball_id"
),
/* extra runs per ball */
extra_runs AS (
    SELECT  "match_id",
            "innings_no",
            "over_id",
            "ball_id",
            SUM("extra_runs")       AS extra_runs
    FROM    IPL.IPL.EXTRA_RUNS
    GROUP BY "match_id","innings_no","over_id","ball_id"
),
/* total runs conceded by every bowler in every over */
over_runs_by_bowler AS (
    SELECT  b."match_id",
            b."innings_no",
            b."over_id",
            b."bowler",
            SUM( COALESCE(br.bat_runs ,0)
               + COALESCE(er.extra_runs,0) )     AS runs_conceded
    FROM    IPL.IPL.BALL_BY_BALL b
    LEFT JOIN bat_runs  br
           ON br."match_id"  = b."match_id"
          AND br."innings_no"= b."innings_no"
          AND br."over_id"   = b."over_id"
          AND br."ball_id"   = b."ball_id"
    LEFT JOIN extra_runs er
           ON er."match_id"  = b."match_id"
          AND er."innings_no"= b."innings_no"
          AND er."over_id"   = b."over_id"
          AND er."ball_id"   = b."ball_id"
    GROUP BY b."match_id", b."innings_no", b."over_id", b."bowler"
),
/* maximum-run over(s) for every match */
max_over_per_match AS (
    SELECT  "match_id",
            MAX(runs_conceded)  AS max_runs_in_match
    FROM    over_runs_by_bowler
    GROUP BY "match_id"
),
match_max_overs AS (
    SELECT  o.*
    FROM    over_runs_by_bowler o
    JOIN    max_over_per_match m
          ON m."match_id" = o."match_id"
         AND m.max_runs_in_match = o.runs_conceded
),
/* keep each bowler’s single best (highest-run) max-over */
best_over_per_bowler AS (
    SELECT  mo."bowler",
            mo."match_id",
            mo.runs_conceded,
            ROW_NUMBER() OVER (PARTITION BY mo."bowler"
                               ORDER BY mo.runs_conceded DESC, mo."match_id") AS rn
    FROM    match_max_overs  mo
),
/* rank bowlers by the runs they conceded in that over */
ranked_bowlers AS (
    SELECT  b."bowler",
            b."match_id",
            b.runs_conceded,
            DENSE_RANK() OVER (ORDER BY b.runs_conceded DESC) AS overall_rank
    FROM    best_over_per_bowler b
    WHERE   b.rn = 1
)
/* top-3 bowlers and the match in which the huge over happened */
SELECT  p."player_name"  AS "bowler_name",
        r."match_id"     AS "match_id",
        r.runs_conceded  AS "runs_conceded_in_over"
FROM    ranked_bowlers   r
JOIN    IPL.IPL.PLAYER   p
      ON p."player_id" = r."bowler"
ORDER BY r.runs_conceded DESC NULLS LAST,
         r."match_id"
LIMIT 3;