WITH batsman_totals AS (
    SELECT 
        m."season_id",
        bb."striker" AS "player_id",
        SUM(bs."runs_scored") AS "total_runs"
    FROM 
        "IPL"."IPL"."BATSMAN_SCORED" AS bs
    JOIN 
        "IPL"."IPL"."BALL_BY_BALL" AS bb
        ON bs."match_id" = bb."match_id" 
        AND bs."over_id" = bb."over_id" 
        AND bs."ball_id" = bb."ball_id"
    JOIN 
        "IPL"."IPL"."MATCH" AS m
        ON bs."match_id" = m."match_id"
    GROUP BY 
        m."season_id",
        bb."striker"
),
batsman_ranked AS (
    SELECT
        bt."season_id",
        bt."player_id",
        bt."total_runs",
        ROW_NUMBER() OVER (
            PARTITION BY bt."season_id" 
            ORDER BY bt."total_runs" DESC NULLS LAST, bt."player_id" ASC
        ) AS "rank"
    FROM
        batsman_totals bt
),
top_batsmen AS (
    SELECT
        br."season_id",
        br."player_id",
        br."total_runs",
        br."rank"
    FROM
        batsman_ranked br
    WHERE
        br."rank" <= 3
),
bowlers_totals AS (
    SELECT
        m."season_id",
        bb."bowler" AS "player_id",
        COUNT(*) AS "total_wickets"
    FROM
        "IPL"."IPL"."WICKET_TAKEN" AS wt
    JOIN
        "IPL"."IPL"."BALL_BY_BALL" AS bb
        ON wt."match_id" = bb."match_id" 
        AND wt."over_id" = bb."over_id" 
        AND wt."ball_id" = bb."ball_id"
    JOIN 
        "IPL"."IPL"."MATCH" AS m
        ON wt."match_id" = m."match_id"
    WHERE
        wt."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY
        m."season_id",
        bb."bowler"
),
bowlers_ranked AS (
    SELECT
        bt."season_id",
        bt."player_id",
        bt."total_wickets",
        ROW_NUMBER() OVER (
            PARTITION BY bt."season_id" 
            ORDER BY bt."total_wickets" DESC NULLS LAST, bt."player_id" ASC
        ) AS "rank"
    FROM
        bowlers_totals bt
),
top_bowlers AS (
    SELECT
        br."season_id",
        br."player_id",
        br."total_wickets",
        br."rank"
    FROM
        bowlers_ranked br
    WHERE
        br."rank" <= 3
),
top_combined AS (
    SELECT
        COALESCE(bat."season_id", bowl."season_id") AS "season_id",
        COALESCE(bat."rank", bowl."rank") AS "position",
        bat_p."player_name" AS "batsman_name",
        bat."total_runs" AS "batsman_runs",
        bowl_p."player_name" AS "bowler_name",
        bowl."total_wickets" AS "bowler_wickets"
    FROM
        top_batsmen bat
    FULL OUTER JOIN
        top_bowlers bowl
        ON bat."season_id" = bowl."season_id" 
        AND bat."rank" = bowl."rank"
    LEFT JOIN
        "IPL"."IPL"."PLAYER" bat_p
        ON bat."player_id" = bat_p."player_id"
    LEFT JOIN
        "IPL"."IPL"."PLAYER" bowl_p
        ON bowl."player_id" = bowl_p."player_id"
)
SELECT
    "season_id",
    "position",
    "batsman_name",
    "batsman_runs",
    "bowler_name",
    "bowler_wickets"
FROM
    top_combined
ORDER BY
    "season_id" ASC NULLS LAST,
    "position" ASC NULLS LAST;