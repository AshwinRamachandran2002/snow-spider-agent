WITH ball_info AS (
    SELECT
        b."match_id",
        b."over_id",
        b."ball_id",
        b."innings_no",
        b."bowler" AS "bowler_id"
    FROM IPL.IPL."BALL_BY_BALL" b
),
batsman_runs AS (
    SELECT
        "match_id",
        "over_id",
        "ball_id",
        "innings_no",
        SUM("runs_scored") AS "bat_runs"
    FROM IPL.IPL."BATSMAN_SCORED"
    GROUP BY 1,2,3,4
),
extras AS (
    SELECT
        "match_id",
        "over_id",
        "ball_id",
        "innings_no",
        "extra_type",
        "extra_runs"
    FROM IPL.IPL."EXTRA_RUNS"
),
ball_runs AS (
    SELECT
        bi."bowler_id",
        COALESCE(br."bat_runs",0)                                              AS "bat_runs",
        CASE WHEN LOWER(ex."extra_type") IN ('wides','noballs')
             THEN ex."extra_runs"
             ELSE 0 END                                                       AS "extra_runs"
    FROM ball_info bi
    LEFT JOIN batsman_runs br
           ON  bi."match_id"  = br."match_id"
           AND bi."over_id"   = br."over_id"
           AND bi."ball_id"   = br."ball_id"
           AND bi."innings_no"= br."innings_no"
    LEFT JOIN extras ex
           ON  bi."match_id"  = ex."match_id"
           AND bi."over_id"   = ex."over_id"
           AND bi."ball_id"   = ex."ball_id"
           AND bi."innings_no"= ex."innings_no"
),
runs_per_bowler AS (
    SELECT
        "bowler_id",
        SUM("bat_runs" + "extra_runs") AS "runs_conceded"
    FROM ball_runs
    GROUP BY "bowler_id"
),
wickets AS (
    SELECT
        bb."bowler" AS "bowler_id",
        COUNT(*)    AS "wickets"
    FROM IPL.IPL."WICKET_TAKEN" wt
    JOIN IPL.IPL."BALL_BY_BALL" bb
         ON  wt."match_id"   = bb."match_id"
         AND wt."over_id"    = bb."over_id"
         AND wt."ball_id"    = bb."ball_id"
         AND wt."innings_no" = bb."innings_no"
    WHERE LOWER(wt."kind_out") NOT IN ('run out','retired hurt',
                                       'retired','obstructing the field',
                                       'retired out','obstruct')
    GROUP BY bb."bowler"
),
bowling_stats AS (
    SELECT
        r."bowler_id",
        r."runs_conceded",
        w."wickets",
        r."runs_conceded" / w."wickets" AS "bowling_avg"
    FROM runs_per_bowler r
    JOIN wickets w
      ON r."bowler_id" = w."bowler_id"
    WHERE w."wickets" > 0
)
SELECT
    p."player_name",
    ROUND(bs."bowling_avg", 4) AS "bowling_average"
FROM bowling_stats bs
JOIN IPL.IPL."PLAYER" p
  ON bs."bowler_id" = p."player_id"
ORDER BY "bowling_average" ASC NULLS LAST
LIMIT 1;