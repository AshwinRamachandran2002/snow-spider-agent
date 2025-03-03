WITH total_stats AS (
    SELECT 
        "player_id", 
        SUM(TRY_TO_NUMERIC("g")) AS "total_games",
        SUM(TRY_TO_NUMERIC("r")) AS "total_runs",
        SUM(TRY_TO_NUMERIC("h")) AS "total_hits",
        SUM(TRY_TO_NUMERIC("hr")) AS "total_hr"
    FROM BASEBALL.BASEBALL.BATTING
    GROUP BY "player_id"
),
top_players AS (
    SELECT 
        ts."player_id",
        ts."total_games",
        ts."total_runs",
        ts."total_hits",
        ts."total_hr",
        p."name_given"
    FROM total_stats ts
    INNER JOIN BASEBALL.BASEBALL.PLAYER p ON ts."player_id" = p."player_id"
),
top_games AS (
    SELECT tp."name_given", tp."total_games" AS "Score"
    FROM top_players tp
    ORDER BY tp."total_games" DESC NULLS LAST, tp."player_id" ASC
    LIMIT 1
),
top_runs AS (
    SELECT tp."name_given", tp."total_runs" AS "Score"
    FROM top_players tp
    ORDER BY tp."total_runs" DESC NULLS LAST, tp."player_id" ASC
    LIMIT 1
),
top_hits AS (
    SELECT tp."name_given", tp."total_hits" AS "Score"
    FROM top_players tp
    ORDER BY tp."total_hits" DESC NULLS LAST, tp."player_id" ASC
    LIMIT 1
),
top_hr AS (
    SELECT tp."name_given", tp."total_hr" AS "Score"
    FROM top_players tp
    ORDER BY tp."total_hr" DESC NULLS LAST, tp."player_id" ASC
    LIMIT 1
)
SELECT 'Games Played' AS "Metric", tg."name_given" AS "Player_Given_Name", tg."Score"
FROM top_games tg

UNION ALL

SELECT 'Runs' AS "Metric", tr."name_given" AS "Player_Given_Name", tr."Score"
FROM top_runs tr

UNION ALL

SELECT 'Hits' AS "Metric", th."name_given" AS "Player_Given_Name", th."Score"
FROM top_hits th

UNION ALL

SELECT 'Home Runs' AS "Metric", thr."name_given" AS "Player_Given_Name", thr."Score"
FROM top_hr thr;