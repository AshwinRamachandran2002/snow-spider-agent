WITH batsman_totals AS (
    SELECT
        bbb."striker" AS "player_id",
        m."season_id",
        SUM(bs."runs_scored") AS "total_runs"
    FROM
        "IPL"."IPL"."BALL_BY_BALL" AS bbb
    JOIN "IPL"."IPL"."BATSMAN_SCORED" AS bs
        ON bbb."match_id" = bs."match_id"
        AND bbb."over_id" = bs."over_id"
        AND bbb."ball_id" = bs."ball_id"
        AND bbb."innings_no" = bs."innings_no"
    JOIN "IPL"."IPL"."MATCH" AS m
        ON bbb."match_id" = m."match_id"
    GROUP BY
        bbb."striker",
        m."season_id"
),

batsman_ranked AS (
    SELECT
        "season_id",
        "player_id",
        "total_runs",
        ROW_NUMBER() OVER (
            PARTITION BY "season_id"
            ORDER BY "total_runs" DESC NULLS LAST, "player_id" ASC
        ) AS "rank"
    FROM
        batsman_totals
),

top_batsmen AS (
    SELECT
        b."season_id",
        b."player_id",
        b."total_runs",
        b."rank"
    FROM
        batsman_ranked b
    WHERE
        b."rank" <= 3
),

batsmen_with_names AS (
    SELECT
        b."season_id",
        b."rank" AS "position",
        p."player_name" AS "batsman_name",
        b."total_runs" AS "batsman_runs"
    FROM
        top_batsmen b
    JOIN
        "IPL"."IPL"."PLAYER" p
        ON b."player_id" = p."player_id"
),

bowler_totals AS (
    SELECT
        bbb."bowler" AS "player_id",
        m."season_id",
        COUNT(*) AS "total_wickets"
    FROM
        "IPL"."IPL"."BALL_BY_BALL" AS bbb
    JOIN "IPL"."IPL"."WICKET_TAKEN" AS wt
        ON bbb."match_id" = wt."match_id"
        AND bbb."over_id" = wt."over_id"
        AND bbb."ball_id" = wt."ball_id"
        AND bbb."innings_no" = wt."innings_no"
    JOIN "IPL"."IPL"."MATCH" AS m
        ON bbb."match_id" = m."match_id"
    WHERE
        wt."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY
        bbb."bowler",
        m."season_id"
),

bowler_ranked AS (
    SELECT
        "season_id",
        "player_id",
        "total_wickets",
        ROW_NUMBER() OVER (
            PARTITION BY "season_id"
            ORDER BY "total_wickets" DESC NULLS LAST, "player_id" ASC
        ) AS "rank"
    FROM
        bowler_totals
),

top_bowlers AS (
    SELECT
        b."season_id",
        b."player_id",
        b."total_wickets",
        b."rank"
    FROM
        bowler_ranked b
    WHERE
        b."rank" <= 3
),

bowlers_with_names AS (
    SELECT
        b."season_id",
        b."rank" AS "position",
        p."player_name" AS "bowler_name",
        b."total_wickets" AS "bowler_wickets"
    FROM
        top_bowlers b
    JOIN
        "IPL"."IPL"."PLAYER" p
        ON b."player_id" = p."player_id"
)

SELECT
    batsmen_with_names."season_id",
    batsmen_with_names."position",
    batsmen_with_names."batsman_name",
    batsmen_with_names."batsman_runs",
    bowlers_with_names."bowler_name",
    bowlers_with_names."bowler_wickets"
FROM
    batsmen_with_names
JOIN
    bowlers_with_names
ON
    batsmen_with_names."season_id" = bowlers_with_names."season_id" AND
    batsmen_with_names."position" = bowlers_with_names."position"
ORDER BY
    batsmen_with_names."season_id" ASC,
    batsmen_with_names."position" ASC;