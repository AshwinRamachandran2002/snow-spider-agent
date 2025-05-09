WITH first_conv AS (
    /* 1. For every session pick the first “/detail” click or “/complete” conversion
          and keep its path & search_type as well as its timestamp.                */
    SELECT
        "session",
        "path",
        "search_type",
        MIN("stamp") AS "conv_stamp"
    FROM "activity_log"
    WHERE "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
    GROUP BY "session"
),
pre_cnt AS (
    /* 2. Count, for each session, how many events with a NON-EMPTY search_type
          occurred BEFORE that first conversion / click.                          */
    SELECT
        a."session",
        SUM(
            CASE
                WHEN COALESCE(a."search_type", '') <> '' THEN 1
                ELSE 0
            END
        ) AS "pre_event_cnt"
    FROM "activity_log" AS a
    JOIN first_conv  AS f
         ON a."session" = f."session"
    WHERE a."stamp" < f."conv_stamp"
    GROUP BY a."session"
),
min_val AS (
    /* 3. Obtain the minimum of those counts                                       */
    SELECT MIN("pre_event_cnt") AS "min_cnt"
    FROM   pre_cnt
)
SELECT
    p."session",
    f."path",
    f."search_type"
FROM pre_cnt   AS p
JOIN min_val   AS m ON p."pre_event_cnt" = m."min_cnt"
JOIN first_conv AS f ON p."session" = f."session";