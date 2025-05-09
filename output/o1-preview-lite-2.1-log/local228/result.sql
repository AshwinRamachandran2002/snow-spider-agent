WITH batsman_runs AS (
    SELECT
        m."season_id" AS "season_id",
        bb."striker" AS "player_id",
        SUM(bs."runs_scored") AS "total_runs"
    FROM
        "batsman_scored" bs
    JOIN
        "ball_by_ball" bb ON bs."match_id" = bb."match_id" AND bs."over_id" = bb."over_id" AND bs."ball_id" = bb."ball_id" AND bs."innings_no" = bb."innings_no"
    JOIN
        "match" m ON bs."match_id" = m."match_id"
    GROUP BY
        m."season_id",
        bb."striker"
),
batsman_rankings AS (
    SELECT
        "season_id",
        "player_id",
        "total_runs",
        ROW_NUMBER() OVER (PARTITION BY "season_id" ORDER BY "total_runs" DESC, "player_id" ASC) AS "rank"
    FROM
        batsman_runs
),
top_batsmen AS (
    SELECT
        br."season_id",
        br."rank",
        p."player_name"
    FROM
        batsman_rankings br
    JOIN
        "player" p ON br."player_id" = p."player_id"
    WHERE
        br."rank" <= 3
),
bowler_wickets AS (
    SELECT
        m."season_id" AS "season_id",
        bb."bowler" AS "player_id",
        COUNT(*) AS "wickets"
    FROM
        "wicket_taken" wt
    JOIN
        "ball_by_ball" bb ON wt."match_id" = bb."match_id" AND wt."over_id" = bb."over_id" AND wt."ball_id" = bb."ball_id" AND wt."innings_no" = bb."innings_no"
    JOIN
        "match" m ON wt."match_id" = m."match_id"
    WHERE
        wt."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY
        m."season_id",
        bb."bowler"
),
bowler_rankings AS (
    SELECT
        "season_id",
        "player_id",
        "wickets",
        ROW_NUMBER() OVER (PARTITION BY "season_id" ORDER BY "wickets" DESC, "player_id" ASC) AS "rank"
    FROM
        bowler_wickets
),
top_bowlers AS (
    SELECT
        br."season_id",
        br."rank",
        p."player_name"
    FROM
        bowler_rankings br
    JOIN
        "player" p ON br."player_id" = p."player_id"
    WHERE
        br."rank" <= 3
),
batsmen_pivot AS (
    SELECT
        "season_id",
        MAX(CASE WHEN "rank"=1 THEN "player_name" END) AS "Batsman1",
        MAX(CASE WHEN "rank"=2 THEN "player_name" END) AS "Batsman2",
        MAX(CASE WHEN "rank"=3 THEN "player_name" END) AS "Batsman3"
    FROM
        top_batsmen
    GROUP BY "season_id"
),
bowlers_pivot AS (
    SELECT
        "season_id",
        MAX(CASE WHEN "rank"=1 THEN "player_name" END) AS "Bowler1",
        MAX(CASE WHEN "rank"=2 THEN "player_name" END) AS "Bowler2",
        MAX(CASE WHEN "rank"=3 THEN "player_name" END) AS "Bowler3"
    FROM
        top_bowlers
    GROUP BY "season_id"
)
SELECT
    batsmen_pivot."season_id" AS "Season",
    batsmen_pivot."Batsman1",
    batsmen_pivot."Batsman2",
    batsmen_pivot."Batsman3",
    bowlers_pivot."Bowler1",
    bowlers_pivot."Bowler2",
    bowlers_pivot."Bowler3"
FROM
    batsmen_pivot
JOIN
    bowlers_pivot USING("season_id")
ORDER BY
    batsmen_pivot."season_id";