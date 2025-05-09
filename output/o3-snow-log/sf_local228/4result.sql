WITH
-- --------------------------------------------------
-- 1.  Total runs scored by every batsman in every season
-- --------------------------------------------------
"Batsman_Runs" AS (
    SELECT
        m."season_id",
        bbb."striker"                         AS "player_id",
        SUM(bs."runs_scored")                 AS "total_runs"
    FROM IPL.IPL."BATSMAN_SCORED"  bs
    JOIN IPL.IPL."BALL_BY_BALL"    bbb
      ON  bs."match_id"   = bbb."match_id"
     AND bs."innings_no" = bbb."innings_no"
     AND bs."over_id"    = bbb."over_id"
     AND bs."ball_id"    = bbb."ball_id"
    JOIN IPL.IPL."MATCH"           m
      ON bs."match_id" = m."match_id"
    GROUP BY
        m."season_id",
        bbb."striker"
),
-- --------------------------------------------------
-- 2.  Pick top-3 batsmen per season (tie-break by smaller player_id)
-- --------------------------------------------------
"Top3_Batsmen" AS (
    SELECT
        "season_id",
        "player_id",
        "total_runs",
        ROW_NUMBER() OVER (
            PARTITION BY "season_id"
            ORDER BY "total_runs" DESC, "player_id" ASC
        )                                     AS "pos"
    FROM "Batsman_Runs"
    QUALIFY "pos" <= 3
),
-- --------------------------------------------------
-- 3.  Total wickets taken by every bowler in every season
--      (excluding run-out, hit-wicket, retired-hurt)
-- --------------------------------------------------
"Bowler_Wkts" AS (
    SELECT
        m."season_id",
        bbb."bowler"                          AS "player_id",
        COUNT(*)                              AS "total_wkts"
    FROM IPL.IPL."WICKET_TAKEN"  wt
    JOIN IPL.IPL."BALL_BY_BALL"  bbb
      ON  wt."match_id"   = bbb."match_id"
     AND wt."innings_no" = bbb."innings_no"
     AND wt."over_id"    = bbb."over_id"
     AND wt."ball_id"    = bbb."ball_id"
    JOIN IPL.IPL."MATCH"         m
      ON wt."match_id" = m."match_id"
    WHERE LOWER(wt."kind_out") NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY
        m."season_id",
        bbb."bowler"
),
-- --------------------------------------------------
-- 4.  Pick top-3 bowlers per season (tie-break by smaller player_id)
-- --------------------------------------------------
"Top3_Bowlers" AS (
    SELECT
        "season_id",
        "player_id",
        "total_wkts",
        ROW_NUMBER() OVER (
            PARTITION BY "season_id"
            ORDER BY "total_wkts" DESC, "player_id" ASC
        )                                     AS "pos"
    FROM "Bowler_Wkts"
    QUALIFY "pos" <= 3
)
-- --------------------------------------------------
-- 5.  Combine matched positions (1 with 1, 2 with 2, 3 with 3)
-- --------------------------------------------------
SELECT
    b."season_id",
    b."player_id"      AS "batsman_id",
    b."total_runs"     AS "batsman_runs",
    w."player_id"      AS "bowler_id",
    w."total_wkts"     AS "bowler_wickets"
FROM "Top3_Batsmen"  b
JOIN "Top3_Bowlers"  w
  ON  b."season_id" = w."season_id"
 AND b."pos"        = w."pos"
ORDER BY
    b."season_id" ASC,
    b."pos"        ASC;