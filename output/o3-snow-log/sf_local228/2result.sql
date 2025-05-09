WITH "SEASON_MATCH" AS (          -- map every match to its season
    SELECT "match_id",
           "season_id"
    FROM "IPL"."IPL"."MATCH"
),

/* ----------  Batsmen : total runs per season ---------- */
"BATTING_AGG" AS (
    SELECT
        sm."season_id",
        bb."striker"                 AS "player_id",
        SUM(bs."runs_scored")        AS "total_runs"
    FROM "IPL"."IPL"."BATSMAN_SCORED" bs
    JOIN "IPL"."IPL"."BALL_BY_BALL"  bb
      ON bs."match_id"   = bb."match_id"
     AND bs."innings_no" = bb."innings_no"
     AND bs."over_id"    = bb."over_id"
     AND bs."ball_id"    = bb."ball_id"
    JOIN "SEASON_MATCH"  sm
      ON bs."match_id" = sm."match_id"
    GROUP BY sm."season_id", bb."striker"
),

"TOP_BATSMEN" AS (                -- keep top-3 per season (tie-break by smaller id)
    SELECT
        "season_id",
        "player_id",
        "total_runs",
        ROW_NUMBER() OVER (
              PARTITION BY "season_id"
              ORDER BY "total_runs" DESC NULLS LAST, "player_id" ASC
        ) AS "rank_no"
    FROM "BATTING_AGG"
    QUALIFY "rank_no" <= 3
),

/* ----------  Bowlers : wickets per season -------------- */
"BOWLING_AGG" AS (
    SELECT
        sm."season_id",
        bb."bowler"                  AS "player_id",
        COUNT(*)                     AS "wickets"
    FROM "IPL"."IPL"."WICKET_TAKEN" wt
    JOIN "IPL"."IPL"."BALL_BY_BALL"  bb
      ON wt."match_id"   = bb."match_id"
     AND wt."innings_no" = bb."innings_no"
     AND wt."over_id"    = bb."over_id"
     AND wt."ball_id"    = bb."ball_id"
    JOIN "SEASON_MATCH"  sm
      ON wt."match_id" = sm."match_id"
    WHERE LOWER(wt."kind_out") NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY sm."season_id", bb."bowler"
),

"TOP_BOWLERS" AS (               -- keep top-3 per season (tie-break by smaller id)
    SELECT
        "season_id",
        "player_id",
        "wickets",
        ROW_NUMBER() OVER (
              PARTITION BY "season_id"
              ORDER BY "wickets" DESC NULLS LAST, "player_id" ASC
        ) AS "rank_no"
    FROM "BOWLING_AGG"
    QUALIFY "rank_no" <= 3
)

/* ----------  Final paired output ----------------------- */
SELECT
    tb."season_id",
    tb."player_id"   AS "batsman_id",
    tb."total_runs"  AS "batsman_runs",
    tw."player_id"   AS "bowler_id",
    tw."wickets"     AS "bowler_wickets"
FROM "TOP_BATSMEN" tb
JOIN "TOP_BOWLERS" tw
  ON tb."season_id" = tw."season_id"
 AND tb."rank_no"   = tw."rank_no"
ORDER BY tb."season_id" ASC,
         tb."rank_no"   ASC;