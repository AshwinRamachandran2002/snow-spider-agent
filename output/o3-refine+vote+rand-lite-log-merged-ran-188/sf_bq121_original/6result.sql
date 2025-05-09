WITH cutoff_date AS (            -- constant reference date
    SELECT TO_TIMESTAMP_LTZ('2021-10-01') AS "cutoff_ts"
),

/* badges earned on or before the cut‑off date */
badge_counts AS (
    SELECT
        "user_id",
        COUNT(*) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW."BADGES" b
    ,   cutoff_date c
    WHERE TO_TIMESTAMP_LTZ(b."date" / 1000000) <= c."cutoff_ts"
    GROUP BY "user_id"
),

/* users who joined on or before the cut‑off date and their completed membership years */
eligible_users AS (
    SELECT
        u."id"                         AS "user_id",
        u."reputation"                 AS "reputation",
        DATEDIFF(
            'year',
            TO_DATE(TO_TIMESTAMP_LTZ(u."creation_date" / 1000000)),
            c."cutoff_ts"::DATE
        )                              AS "member_years"
    FROM STACKOVERFLOW.STACKOVERFLOW."USERS" u
    ,   cutoff_date c
    WHERE TO_TIMESTAMP_LTZ(u."creation_date" / 1000000) <= c."cutoff_ts"
),

/* join users with their badge totals (missing = 0) */
user_stats AS (
    SELECT
        e."member_years",
        e."reputation",
        COALESCE(b."badge_count", 0)   AS "badge_count"
    FROM eligible_users e
    LEFT JOIN badge_counts b
           ON e."user_id" = b."user_id"
)

/* final aggregation */
SELECT
    "member_years",
    AVG("reputation")   AS "avg_reputation",
    AVG("badge_count")  AS "avg_badges"
FROM user_stats
GROUP BY "member_years"
ORDER BY "member_years";