/*====================================================================
  For every bowler
    • total wickets  (excluding run-out / retired-hurt / obstructing)
    • economy rate   (runs-off-the-bat  ÷ overs bowled)
    • strike rate    (balls bowled per wicket)
    • best figures   (most wickets in a single match, shown “wkts-runs”)
====================================================================*/
WITH ball_data AS (          -- balls & runs-off-bat for each bowler-match
    SELECT
        bb."bowler"                         AS "bowler_id",
        bb."match_id",
        COUNT(*)                            AS "balls_bowled",
        SUM(bs."runs_scored")               AS "runs_off_bat"
    FROM IPL.IPL."BALL_BY_BALL"   bb
    JOIN IPL.IPL."BATSMAN_SCORED" bs
          ON  bb."match_id"   = bs."match_id"
          AND bb."innings_no" = bs."innings_no"
          AND bb."over_id"    = bs."over_id"
          AND bb."ball_id"    = bs."ball_id"
    GROUP BY bb."bowler", bb."match_id"
),
wicket_data AS (             -- credited wickets for each bowler-match
    SELECT
        bb."bowler"                         AS "bowler_id",
        bb."match_id",
        SUM( CASE
                 WHEN wt."player_out" IS NOT NULL
                  AND wt."kind_out" NOT IN ('run out',
                                            'retired hurt',
                                            'obstructing the field')
                 THEN 1 ELSE 0 END )        AS "wickets"
    FROM IPL.IPL."BALL_BY_BALL"  bb
    LEFT JOIN IPL.IPL."WICKET_TAKEN" wt
           ON  bb."match_id"   = wt."match_id"
           AND bb."innings_no" = wt."innings_no"
           AND bb."over_id"    = wt."over_id"
           AND bb."ball_id"    = wt."ball_id"
    GROUP BY bb."bowler", bb."match_id"
),
match_stats AS (             -- combine runs, balls, wickets per match
    SELECT
        bd."bowler_id",
        bd."match_id",
        bd."balls_bowled",
        bd."runs_off_bat",
        COALESCE(wd."wickets",0)            AS "wickets"
    FROM ball_data  bd
    LEFT JOIN wicket_data wd
           ON  bd."bowler_id" = wd."bowler_id"
           AND bd."match_id"  = wd."match_id"
),
agg_stats AS (               -- career aggregates for every bowler
    SELECT
        "bowler_id",
        SUM("balls_bowled")                 AS "total_balls",
        SUM("runs_off_bat")                 AS "total_runs",
        SUM("wickets")                      AS "total_wickets"
    FROM match_stats
    GROUP BY "bowler_id"
),
best_per_match AS (          -- rank matches by wickets, then runs
    SELECT
        "bowler_id",
        "wickets"              AS "match_wkts",
        "runs_off_bat"         AS "match_runs",
        ROW_NUMBER() OVER (PARTITION BY "bowler_id"
                           ORDER BY "wickets" DESC,
                                    "runs_off_bat" ASC)  AS rn
    FROM match_stats
),
best_perf AS (               -- keep best match per bowler
    SELECT "bowler_id",
           "match_wkts",
           "match_runs"
    FROM best_per_match
    WHERE rn = 1
)
SELECT
    p."player_name",
    a."total_wickets",
    ROUND( (a."total_runs" * 6.0) / a."total_balls", 2)                         AS "economy_rate",
    ROUND( CASE WHEN a."total_wickets" = 0
                THEN NULL
                ELSE a."total_balls" / a."total_wickets" END, 2)                AS "strike_rate",
    CONCAT(best."match_wkts", '-', best."match_runs")                           AS "best_bowling"
FROM agg_stats           a
JOIN best_perf          best  ON best."bowler_id" = a."bowler_id"
JOIN IPL.IPL."PLAYER"    p    ON p."player_id"   = a."bowler_id"
ORDER BY a."total_wickets" DESC NULLS LAST;