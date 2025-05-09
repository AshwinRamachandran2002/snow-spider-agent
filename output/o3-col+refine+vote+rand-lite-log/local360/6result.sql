WITH first_target AS (
    SELECT
        "session",
        MIN("stamp") AS "first_click_time"
    FROM "activity_log"
    WHERE "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
    GROUP BY "session"
),
pre_events AS (
    SELECT
        l."session",
        l."path",
        l."search_type",
        l."stamp"
    FROM "activity_log" AS l
    JOIN first_target AS f
      ON l."session" = f."session"
    WHERE l."search_type" IS NOT NULL
      AND l."search_type" <> ''
      AND l."stamp" < f."first_click_time"
),
cnts AS (
    SELECT
        "session",
        COUNT(*) AS "cnt"
    FROM pre_events
    GROUP BY "session"
),
min_cnt AS (
    SELECT MIN("cnt") AS "min_value"
    FROM cnts
)
SELECT
    p."session",
    p."path",
    p."search_type"
FROM pre_events AS p
JOIN cnts      AS c ON p."session" = c."session"
JOIN min_cnt   AS m ON c."cnt" = m."min_value"
ORDER BY
    p."session",
    p."stamp";