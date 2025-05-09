WITH batsman_totals AS (
    SELECT
        m."season_id",
        bbb."striker" AS "player_id",
        SUM(bs."runs_scored") AS "total_runs"
    FROM "IPL"."IPL"."BATSMAN_SCORED" bs
    JOIN "IPL"."IPL"."BALL_BY_BALL" bbb
        ON bs."match_id" = bbb."match_id"
        AND bs."over_id" = bbb."over_id"
        AND bs."ball_id" = bbb."ball_id"
    JOIN "IPL"."IPL"."MATCH" m
        ON bs."match_id" = m."match_id"
    GROUP BY m."season_id", bbb."striker"
),
batsman_ranked AS (
    SELECT
        "season_id",
        "player_id",
        "total_runs",
        ROW_NUMBER() OVER (
            PARTITION BY "season_id" 
            ORDER BY "total_runs" DESC NULLS LAST, "player_id" ASC
        ) AS "batsman_rank"
    FROM batsman_totals
),
top_batsmen AS (
    SELECT
        br."season_id",
        br."player_id",
        br."total_runs",
        br."batsman_rank",
        p."player_name"
    FROM batsman_ranked br
    JOIN "IPL"."IPL"."PLAYER" p
        ON br."player_id" = p."player_id"
    WHERE br."batsman_rank" <= 3
),
bowler_totals AS (
    SELECT
        m."season_id",
        bbb."bowler" AS "player_id",
        COUNT(*) AS "wickets"
    FROM "IPL"."IPL"."WICKET_TAKEN" wt
    JOIN "IPL"."IPL"."BALL_BY_BALL" bbb
        ON wt."match_id" = bbb."match_id"
        AND wt."over_id" = bbb."over_id"
        AND wt."ball_id" = bbb."ball_id"
    JOIN "IPL"."IPL"."MATCH" m
        ON wt."match_id" = m."match_id"
    WHERE wt."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m."season_id", bbb."bowler"
),
bowler_ranked AS (
    SELECT
        "season_id",
        "player_id",
        "wickets",
        ROW_NUMBER() OVER (
            PARTITION BY "season_id" 
            ORDER BY "wickets" DESC NULLS LAST, "player_id" ASC
        ) AS "bowler_rank"
    FROM bowler_totals
),
top_bowlers AS (
    SELECT
        br."season_id",
        br."player_id",
        br."wickets",
        br."bowler_rank",
        p."player_name"
    FROM bowler_ranked br
    JOIN "IPL"."IPL"."PLAYER" p
        ON br."player_id" = p."player_id"
    WHERE br."bowler_rank" <= 3
),
batsmen_pivot AS (
    SELECT
        "season_id",
        MAX(CASE WHEN "batsman_rank" = 1 THEN "player_name" END) AS "Batsman1_Name",
        MAX(CASE WHEN "batsman_rank" = 1 THEN "total_runs" END) AS "Batsman1_Runs",
        MAX(CASE WHEN "batsman_rank" = 2 THEN "player_name" END) AS "Batsman2_Name",
        MAX(CASE WHEN "batsman_rank" = 2 THEN "total_runs" END) AS "Batsman2_Runs",
        MAX(CASE WHEN "batsman_rank" = 3 THEN "player_name" END) AS "Batsman3_Name",
        MAX(CASE WHEN "batsman_rank" = 3 THEN "total_runs" END) AS "Batsman3_Runs"
    FROM top_batsmen
    GROUP BY "season_id"
),
bowlers_pivot AS (
    SELECT
        "season_id",
        MAX(CASE WHEN "bowler_rank" = 1 THEN "player_name" END) AS "Bowler1_Name",
        MAX(CASE WHEN "bowler_rank" = 1 THEN "wickets" END) AS "Bowler1_Wickets",
        MAX(CASE WHEN "bowler_rank" = 2 THEN "player_name" END) AS "Bowler2_Name",
        MAX(CASE WHEN "bowler_rank" = 2 THEN "wickets" END) AS "Bowler2_Wickets",
        MAX(CASE WHEN "bowler_rank" = 3 THEN "player_name" END) AS "Bowler3_Name",
        MAX(CASE WHEN "bowler_rank" = 3 THEN "wickets" END) AS "Bowler3_Wickets"
    FROM top_bowlers
    GROUP BY "season_id"
)
SELECT
    COALESCE(b."season_id", bo."season_id") AS "Season",
    b."Batsman1_Name",
    b."Batsman1_Runs",
    b."Batsman2_Name",
    b."Batsman2_Runs",
    b."Batsman3_Name",
    b."Batsman3_Runs",
    bo."Bowler1_Name",
    bo."Bowler1_Wickets",
    bo."Bowler2_Name",
    bo."Bowler2_Wickets",
    bo."Bowler3_Name",
    bo."Bowler3_Wickets"
FROM batsmen_pivot b
FULL OUTER JOIN bowlers_pivot bo
    ON b."season_id" = bo."season_id"
ORDER BY "Season";