WITH "totals" AS (
    SELECT
        "PLAYER_ID",
        SUM(COALESCE(TRY_TO_NUMBER("G"), 0))  AS "TOTAL_GAMES",
        SUM(COALESCE(TRY_TO_NUMBER("R"), 0))  AS "TOTAL_RUNS",
        SUM(COALESCE(TRY_TO_NUMBER("H"), 0))  AS "TOTAL_HITS",
        SUM(COALESCE(TRY_TO_NUMBER("HR"), 0)) AS "TOTAL_HR"
    FROM BASEBALL.BASEBALL.BATTING
    GROUP BY "PLAYER_ID"
),
"max_vals" AS (
    SELECT
        MAX("TOTAL_GAMES") AS "MAX_GAMES",
        MAX("TOTAL_RUNS")  AS "MAX_RUNS",
        MAX("TOTAL_HITS")  AS "MAX_HITS",
        MAX("TOTAL_HR")    AS "MAX_HR"
    FROM "totals"
),
"leaders" AS (
    SELECT "PLAYER_ID", 'Games Played' AS "METRIC", "TOTAL_GAMES" AS "SCORE"
    FROM "totals", "max_vals"
    WHERE "TOTAL_GAMES" = "MAX_GAMES"

    UNION ALL

    SELECT "PLAYER_ID", 'Runs' AS "METRIC", "TOTAL_RUNS" AS "SCORE"
    FROM "totals", "max_vals"
    WHERE "TOTAL_RUNS" = "MAX_RUNS"

    UNION ALL

    SELECT "PLAYER_ID", 'Hits' AS "METRIC", "TOTAL_HITS" AS "SCORE"
    FROM "totals", "max_vals"
    WHERE "TOTAL_HITS" = "MAX_HITS"

    UNION ALL

    SELECT "PLAYER_ID", 'Home Runs' AS "METRIC", "TOTAL_HR" AS "SCORE"
    FROM "totals", "max_vals"
    WHERE "TOTAL_HR" = "MAX_HR"
)
SELECT
    p."NAME_GIVEN",
    l."METRIC",
    l."SCORE"
FROM "leaders" l
JOIN BASEBALL.BASEBALL.PLAYER p
      ON l."PLAYER_ID" = p."PLAYER_ID"
ORDER BY l."METRIC", p."NAME_GIVEN";