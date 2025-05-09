/* -------------------------------------------------------------
   1.  Aggregate runs scored by batsmen                       */
WITH batsman_runs AS (
    SELECT
        "match_id",
        "innings_no",
        "over_id",
        SUM("runs_scored")                AS "bat_runs"
    FROM IPL.IPL.BATSMAN_SCORED
    GROUP BY 1,2,3
),

/* -------------------------------------------------------------
   2.  Aggregate extra runs                                   */
extra_runs AS (
    SELECT
        "match_id",
        "innings_no",
        "over_id",
        SUM("extra_runs")                 AS "ext_runs"
    FROM IPL.IPL.EXTRA_RUNS
    GROUP BY 1,2,3
),

/* -------------------------------------------------------------
   3.  Total runs per over  (batsman + extras)                */
over_totals AS (
    SELECT
        COALESCE(b."match_id",  e."match_id")   AS "match_id",
        COALESCE(b."innings_no",e."innings_no") AS "innings_no",
        COALESCE(b."over_id",   e."over_id")    AS "over_id",
        COALESCE(b."bat_runs",0) + COALESCE(e."ext_runs",0)  AS "total_runs"
    FROM batsman_runs b
    FULL JOIN extra_runs  e
           ON b."match_id"   = e."match_id"
          AND b."innings_no" = e."innings_no"
          AND b."over_id"    = e."over_id"
),

/* -------------------------------------------------------------
   4.  Pick the highest-run over for every (match, innings)   */
max_over_per_innings AS (
    SELECT *
    FROM (
        SELECT
            ot.*,
            ROW_NUMBER() OVER (PARTITION BY "match_id","innings_no"
                               ORDER BY "total_runs" DESC NULLS LAST) AS rn_inn
        FROM over_totals ot
    )
    WHERE rn_inn = 1
),

/* -------------------------------------------------------------
   5.  From the two innings, keep the single best over
       (highest runs) for each match                           */
max_over_per_match AS (
    SELECT *
    FROM (
        SELECT
            mi.*,
            ROW_NUMBER() OVER (PARTITION BY "match_id"
                               ORDER BY "total_runs" DESC NULLS LAST) AS rn_match
        FROM max_over_per_innings mi
    )
    WHERE rn_match = 1
),

/* -------------------------------------------------------------
   6.  Identify the bowler who delivered that over            */
over_bowler AS (
    SELECT DISTINCT   /* DISTINCT – safeguard if data anomaly causes >1 bowler */
        m."match_id",
        m."innings_no",
        m."over_id",
        m."total_runs",
        bb."bowler"                   AS "bowler_id"
    FROM max_over_per_match  m
    JOIN IPL.IPL.BALL_BY_BALL bb
      ON  m."match_id"   = bb."match_id"
     AND  m."innings_no" = bb."innings_no"
     AND  m."over_id"    = bb."over_id"
),

/* -------------------------------------------------------------
   7.  Attach bowler name for readability                      */
over_bowler_named AS (
    SELECT
        ob."match_id",
        ob."innings_no",
        ob."over_id",
        ob."total_runs",
        ob."bowler_id",
        p."player_name"               AS "bowler_name"
    FROM over_bowler ob
    JOIN IPL.IPL.PLAYER p
      ON ob."bowler_id" = p."player_id"
),

/* -------------------------------------------------------------
   8.  Compute the overall average of the highest-over totals  */
final AS (
    SELECT
        obn.*,
        AVG(obn."total_runs") OVER ()  AS "avg_highest_over_runs_across_matches"
    FROM over_bowler_named  obn
)

/* -------------------------------------------------------------
   9.  Return per-match detail + overall average               */
SELECT
    "match_id",
    "innings_no",
    "over_id",
    "total_runs",
    "bowler_id",
    "bowler_name",
    "avg_highest_over_runs_across_matches"
FROM final
ORDER BY "match_id";