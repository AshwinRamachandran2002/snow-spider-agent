WITH batsman_runs AS (
    SELECT
        m."season_id",
        bb."striker" AS "player_id",
        SUM(bs."runs_scored") AS total_runs
    FROM
        IPL.IPL."BATSMAN_SCORED" bs
    JOIN
        IPL.IPL."BALL_BY_BALL" bb
        ON bs."match_id" = bb."match_id"
        AND bs."over_id" = bb."over_id"
        AND bs."ball_id" = bb."ball_id"
        AND bs."innings_no" = bb."innings_no"
    JOIN
        IPL.IPL."MATCH" m
        ON bs."match_id" = m."match_id"
    GROUP BY
        m."season_id", bb."striker"
),
batsman_ranked AS (
    SELECT
        "season_id",
        "player_id",
        total_runs,
        ROW_NUMBER() OVER (
            PARTITION BY "season_id"
            ORDER BY total_runs DESC NULLS LAST, "player_id" ASC
        ) AS rank
    FROM batsman_runs
),
batsman_top3 AS (
    SELECT 
        b."season_id",
        p1."player_name" AS "Batsman1_Name",
        b.batsman1_runs AS "Batsman1_Runs",
        p2."player_name" AS "Batsman2_Name",
        b.batsman2_runs AS "Batsman2_Runs",
        p3."player_name" AS "Batsman3_Name",
        b.batsman3_runs AS "Batsman3_Runs"
    FROM (
        SELECT
            "season_id",
            MAX(CASE WHEN rank = 1 THEN "player_id" END) AS batsman1_id,
            MAX(CASE WHEN rank = 1 THEN total_runs END) AS batsman1_runs,
            MAX(CASE WHEN rank = 2 THEN "player_id" END) AS batsman2_id,
            MAX(CASE WHEN rank = 2 THEN total_runs END) AS batsman2_runs,
            MAX(CASE WHEN rank = 3 THEN "player_id" END) AS batsman3_id,
            MAX(CASE WHEN rank = 3 THEN total_runs END) AS batsman3_runs
        FROM batsman_ranked
        WHERE rank <= 3
        GROUP BY "season_id"
    ) b
    LEFT JOIN IPL.IPL."PLAYER" p1 ON b.batsman1_id = p1."player_id"
    LEFT JOIN IPL.IPL."PLAYER" p2 ON b.batsman2_id = p2."player_id"
    LEFT JOIN IPL.IPL."PLAYER" p3 ON b.batsman3_id = p3."player_id"
),
bowlers_wickets AS (
    SELECT
        m."season_id",
        bb."bowler" AS "player_id",
        COUNT(*) AS total_wickets
    FROM
        IPL.IPL."WICKET_TAKEN" wt
    JOIN
        IPL.IPL."BALL_BY_BALL" bb
        ON wt."match_id" = bb."match_id"
        AND wt."over_id" = bb."over_id"
        AND wt."ball_id" = bb."ball_id"
        AND wt."innings_no" = bb."innings_no"
    JOIN
        IPL.IPL."MATCH" m
        ON wt."match_id" = m."match_id"
    WHERE
        wt."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY
        m."season_id", bb."bowler"
),
bowler_ranked AS (
    SELECT
        "season_id",
        "player_id",
        total_wickets,
        ROW_NUMBER() OVER (
            PARTITION BY "season_id"
            ORDER BY total_wickets DESC NULLS LAST, "player_id" ASC
        ) AS rank
    FROM bowlers_wickets
),
bowler_top3 AS (
    SELECT 
        b."season_id",
        p1."player_name" AS "Bowler1_Name",
        b.bowler1_wickets AS "Bowler1_Wickets",
        p2."player_name" AS "Bowler2_Name",
        b.bowler2_wickets AS "Bowler2_Wickets",
        p3."player_name" AS "Bowler3_Name",
        b.bowler3_wickets AS "Bowler3_Wickets"
    FROM (
        SELECT
            "season_id",
            MAX(CASE WHEN rank = 1 THEN "player_id" END) AS bowler1_id,
            MAX(CASE WHEN rank = 1 THEN total_wickets END) AS bowler1_wickets,
            MAX(CASE WHEN rank = 2 THEN "player_id" END) AS bowler2_id,
            MAX(CASE WHEN rank = 2 THEN total_wickets END) AS bowler2_wickets,
            MAX(CASE WHEN rank = 3 THEN "player_id" END) AS bowler3_id,
            MAX(CASE WHEN rank = 3 THEN total_wickets END) AS bowler3_wickets
        FROM bowler_ranked
        WHERE rank <= 3
        GROUP BY "season_id"
    ) b
    LEFT JOIN IPL.IPL."PLAYER" p1 ON b.bowler1_id = p1."player_id"
    LEFT JOIN IPL.IPL."PLAYER" p2 ON b.bowler2_id = p2."player_id"
    LEFT JOIN IPL.IPL."PLAYER" p3 ON b.bowler3_id = p3."player_id"
)
SELECT
    b."season_id" AS "Season",
    b."Batsman1_Name",
    b."Batsman1_Runs",
    b."Batsman2_Name",
    b."Batsman2_Runs",
    b."Batsman3_Name",
    b."Batsman3_Runs",
    w."Bowler1_Name",
    w."Bowler1_Wickets",
    w."Bowler2_Name",
    w."Bowler2_Wickets",
    w."Bowler3_Name",
    w."Bowler3_Wickets"
FROM
    batsman_top3 b
JOIN
    bowler_top3 w
ON
    b."season_id" = w."season_id"
ORDER BY
    b."season_id" ASC;