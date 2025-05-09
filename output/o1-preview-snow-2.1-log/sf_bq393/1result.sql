WITH last_activity AS (
    SELECT
        "by",
        MAX("time") AS "last_time",
        EXTRACT(MONTH FROM TO_TIMESTAMP(MAX("time"))) AS "Last_active_month",
        EXTRACT(YEAR FROM TO_TIMESTAMP(MAX("time"))) AS "Last_active_year"
    FROM "HACKER_NEWS"."HACKER_NEWS"."FULL"
    WHERE
        "by" IS NOT NULL AND TRIM("by") != ''
        AND "time" <= DATE_PART(EPOCH_SECOND, TIMESTAMP '2023-09-10 00:00:00')
    GROUP BY "by"
),
inactive_users AS (
    SELECT
        "by",
        "last_time",
        "Last_active_month"
    FROM last_activity
    WHERE NOT ("Last_active_year" = 2023 AND "Last_active_month" = 9)
)
SELECT
    u."id" AS "ID",
    i."Last_active_month" AS "Last_active_month"
FROM inactive_users i
JOIN "HACKER_NEWS"."HACKER_NEWS"."FULL" u
    ON i."by" = u."by" AND u."time" = i."last_time"
ORDER BY i."Last_active_month" DESC NULLS LAST
LIMIT 1;