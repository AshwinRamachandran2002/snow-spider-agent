WITH batsman_runs AS (
    SELECT 
        m."season_id", 
        bb."striker" AS "player_id", 
        SUM(bs."runs_scored") AS total_runs
    FROM "ball_by_ball" AS bb
    JOIN "batsman_scored" AS bs
        ON bb."match_id" = bs."match_id" AND
           bb."over_id" = bs."over_id" AND
           bb."ball_id" = bs."ball_id" AND
           bb."innings_no" = bs."innings_no"
    JOIN "match" AS m
        ON bb."match_id" = m."match_id"
    GROUP BY m."season_id", bb."striker"
),
batsman_ranked AS (
    SELECT 
        "season_id", 
        "player_id",
        "total_runs",
        ROW_NUMBER() OVER (
            PARTITION BY "season_id" 
            ORDER BY "total_runs" DESC, "player_id" ASC
        ) AS rank
    FROM batsman_runs
),
top_batsmen AS (
    SELECT 
        "season_id", 
        "player_id",
        rank
    FROM batsman_ranked
    WHERE rank <= 3
),
bowler_wickets AS (
    SELECT 
        m."season_id", 
        bb."bowler" AS "player_id", 
        COUNT(*) AS wickets
    FROM "ball_by_ball" AS bb
    JOIN "wicket_taken" AS wt
        ON bb."match_id" = wt."match_id" AND
           bb."over_id" = wt."over_id" AND
           bb."ball_id" = wt."ball_id" AND
           bb."innings_no" = wt."innings_no"
    JOIN "match" AS m
        ON bb."match_id" = m."match_id"
    WHERE wt."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m."season_id", bb."bowler"
),
bowler_ranked AS (
    SELECT 
        "season_id", 
        "player_id",
        "wickets",
        ROW_NUMBER() OVER (
            PARTITION BY "season_id" 
            ORDER BY "wickets" DESC, "player_id" ASC
        ) AS rank
    FROM bowler_wickets
),
top_bowlers AS (
    SELECT 
        "season_id", 
        "player_id",
        rank
    FROM bowler_ranked
    WHERE rank <=3
)
SELECT
    s."season_id" AS Season,
    b1."player_name" AS Batsman1,
    b2."player_name" AS Batsman2,
    b3."player_name" AS Batsman3,
    bow1."player_name" AS Bowler1,
    bow2."player_name" AS Bowler2,
    bow3."player_name" AS Bowler3
FROM (
    SELECT DISTINCT "season_id" FROM "match"
) AS s
LEFT JOIN (
    SELECT "season_id", "player_id"
    FROM top_batsmen
    WHERE rank = 1
) AS tb1 ON s."season_id" = tb1."season_id"
LEFT JOIN "player" AS b1 ON tb1."player_id" = b1."player_id"

LEFT JOIN (
    SELECT "season_id", "player_id"
    FROM top_batsmen
    WHERE rank = 2
) AS tb2 ON s."season_id" = tb2."season_id"
LEFT JOIN "player" AS b2 ON tb2."player_id" = b2."player_id"

LEFT JOIN (
    SELECT "season_id", "player_id"
    FROM top_batsmen
    WHERE rank = 3
) AS tb3 ON s."season_id" = tb3."season_id"
LEFT JOIN "player" AS b3 ON tb3."player_id" = b3."player_id"

LEFT JOIN (
    SELECT "season_id", "player_id"
    FROM top_bowlers
    WHERE rank = 1
) AS tbow1 ON s."season_id" = tbow1."season_id"
LEFT JOIN "player" AS bow1 ON tbow1."player_id" = bow1."player_id"

LEFT JOIN (
    SELECT "season_id", "player_id"
    FROM top_bowlers
    WHERE rank = 2
) AS tbow2 ON s."season_id" = tbow2."season_id"
LEFT JOIN "player" AS bow2 ON tbow2."player_id" = bow2."player_id"

LEFT JOIN (
    SELECT "season_id", "player_id"
    FROM top_bowlers
    WHERE rank = 3
) AS tbow3 ON s."season_id" = tbow3."season_id"
LEFT JOIN "player" AS bow3 ON tbow3."player_id" = bow3."player_id"

ORDER BY s."season_id" ASC;