WITH "PLAYER_BASE" AS (      --------------------------------------------------
    SELECT
        "player_id",
        "player_name",
        "batting_hand",
        "bowling_skill"
    FROM IPL.IPL.PLAYER
),                           --------------------------------------------------
/* matches played & most-frequent role */
"MATCHES_PLAYED" AS (
    SELECT
        "player_id",
        COUNT(DISTINCT "match_id") AS "matches_played"
    FROM IPL.IPL.PLAYER_MATCH
    GROUP BY "player_id"
),
"ROLE_COUNT" AS (
    SELECT
        "player_id",
        "role",
        COUNT(*)                                           AS "role_cnt",
        ROW_NUMBER() OVER (PARTITION BY "player_id"
                           ORDER BY COUNT(*) DESC, "role") AS "rn"
    FROM IPL.IPL.PLAYER_MATCH
    GROUP BY "player_id","role"
),
"MOST_ROLE" AS (
    SELECT
        "player_id",
        "role" AS "most_role"
    FROM   "ROLE_COUNT"
    WHERE  "rn" = 1
),                           --------------------------------------------------
/* batting – runs & balls faced per match */
"BATTING_PER_MATCH" AS (
    SELECT
        bb."striker"                                        AS "player_id",
        bb."match_id",
        SUM(bs."runs_scored")                               AS "runs_in_match",
        COUNT(*)                                            AS "balls_faced_in_match"
    FROM IPL.IPL.BALL_BY_BALL  bb
    JOIN IPL.IPL.BATSMAN_SCORED bs
      ON  bb."match_id"   = bs."match_id"
     AND  bb."innings_no" = bs."innings_no"
     AND  bb."over_id"    = bs."over_id"
     AND  bb."ball_id"    = bs."ball_id"
    GROUP BY bb."striker", bb."match_id"
),
"BATTING_AGG" AS (
    SELECT
        "player_id",
        SUM("runs_in_match")                                   AS "total_runs",
        SUM("balls_faced_in_match")                            AS "total_balls",
        MAX("runs_in_match")                                   AS "highest_score",
        SUM(CASE WHEN "runs_in_match" >=  30 THEN 1 ELSE 0 END) AS "matches_30_plus",
        SUM(CASE WHEN "runs_in_match" >=  50 THEN 1 ELSE 0 END) AS "matches_50_plus",
        SUM(CASE WHEN "runs_in_match" >= 100 THEN 1 ELSE 0 END) AS "matches_100_plus"
    FROM "BATTING_PER_MATCH"
    GROUP BY "player_id"
),                           --------------------------------------------------
/* dismissals */
"DISMISSALS" AS (
    SELECT
        "player_out" AS "player_id",
        COUNT(*)     AS "dismissals"
    FROM IPL.IPL.WICKET_TAKEN
    GROUP BY "player_out"
),                           --------------------------------------------------
/* bowling – runs conceded, balls bowled, wickets per match */
"BOWLING_PER_MATCH" AS (
    SELECT
        bb."bowler"                                         AS "player_id",
        bb."match_id",
        SUM(COALESCE(bs."runs_scored",0))                   AS "runs_conceded_in_match",
        COUNT(*)                                            AS "balls_bowled_in_match",
        SUM(CASE WHEN wt."player_out" IS NOT NULL 
                 THEN 1 ELSE 0 END)                        AS "wickets_in_match"
    FROM IPL.IPL.BALL_BY_BALL bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
      ON  bb."match_id"   = bs."match_id"
     AND  bb."innings_no" = bs."innings_no"
     AND  bb."over_id"    = bs."over_id"
     AND  bb."ball_id"    = bs."ball_id"
    LEFT JOIN IPL.IPL.WICKET_TAKEN wt
      ON  bb."match_id"   = wt."match_id"
     AND  bb."innings_no" = wt."innings_no"
     AND  bb."over_id"    = wt."over_id"
     AND  bb."ball_id"    = wt."ball_id"
    GROUP BY bb."bowler", bb."match_id"
),
"BOWLING_AGG" AS (
    SELECT
        "player_id",
        SUM("runs_conceded_in_match")  AS "total_runs_conceded",
        SUM("balls_bowled_in_match")   AS "total_balls_bowled",
        SUM("wickets_in_match")        AS "total_wickets"
    FROM "BOWLING_PER_MATCH"
    GROUP BY "player_id"
),                           --------------------------------------------------
/* best bowling figure */
"BEST_BOWLING_RAW" AS (
    SELECT
        "player_id",
        "wickets_in_match",
        "runs_conceded_in_match",
        ROW_NUMBER() OVER (PARTITION BY "player_id"
                           ORDER BY "wickets_in_match" DESC, 
                                    "runs_conceded_in_match" ASC) AS "rn"
    FROM "BOWLING_PER_MATCH"
),
"BEST_BOWLING" AS (
    SELECT
        "player_id",
        CONCAT("wickets_in_match",'-',"runs_conceded_in_match") AS "best_figures"
    FROM "BEST_BOWLING_RAW"
    WHERE "rn" = 1
)                            --------------------------------------------------
/* final output */
SELECT
    pb."player_id",
    pb."player_name",
    COALESCE(mr."most_role",'')                              AS "most_frequent_role",
    pb."batting_hand",
    pb."bowling_skill",
    COALESCE(bat."total_runs",0)                             AS "total_runs",
    COALESCE(mp."matches_played",0)                          AS "total_matches",
    COALESCE(dis."dismissals",0)                             AS "total_dismissals",
    CASE
        WHEN COALESCE(dis."dismissals",0) = 0 THEN NULL
        ELSE ROUND(COALESCE(bat."total_runs",0) / dis."dismissals", 4)
    END                                                     AS "batting_average",
    COALESCE(bat."highest_score",0)                          AS "highest_score",
    COALESCE(bat."matches_30_plus",0)                        AS "matches_30_plus",
    COALESCE(bat."matches_50_plus",0)                        AS "matches_50_plus",
    COALESCE(bat."matches_100_plus",0)                       AS "matches_100_plus",
    COALESCE(bat."total_balls",0)                            AS "total_balls_faced",
    CASE
        WHEN COALESCE(bat."total_balls",0) = 0 THEN NULL
        ELSE ROUND(COALESCE(bat."total_runs",0) * 100.0 / bat."total_balls", 4)
    END                                                     AS "strike_rate",
    COALESCE(bowl."total_wickets",0)                         AS "total_wickets",
    CASE
        WHEN COALESCE(bowl."total_balls_bowled",0) = 0 THEN NULL
        ELSE ROUND(bowl."total_runs_conceded" * 6.0 / bowl."total_balls_bowled", 4)
    END                                                     AS "economy_rate",
    bb."best_figures"                                        AS "best_bowling"
FROM "PLAYER_BASE"      pb
LEFT JOIN "MOST_ROLE"       mr   USING ("player_id")
LEFT JOIN "MATCHES_PLAYED"  mp   USING ("player_id")
LEFT JOIN "BATTING_AGG"     bat  USING ("player_id")
LEFT JOIN "DISMISSALS"      dis  USING ("player_id")
LEFT JOIN "BOWLING_AGG"     bowl USING ("player_id")
LEFT JOIN "BEST_BOWLING"    bb   USING ("player_id")
ORDER BY pb."player_id";