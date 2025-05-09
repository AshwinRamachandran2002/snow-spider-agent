WITH cutoff AS (   -- constant values used for every row
    SELECT 
        1633046400000000::NUMBER  AS "cutoff_epoch_us" ,          -- 01-Oct-2021 00:00:00 UTC in µs
        31557600000000::NUMBER    AS "us_per_year"                -- 365.25 days in µs
),

/* 1.  badge counts for every user */
"badge_counts" AS (
    SELECT 
        "user_id",
        COUNT(*) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW."BADGES"
    GROUP BY "user_id"
),

/* 2.  work out each user’s completed years of membership
       and attach their total badges                     */
"user_cohorts" AS (
    SELECT
        u."id"                                                      AS "user_id",
        FLOOR( (c."cutoff_epoch_us" - u."creation_date")
               / c."us_per_year" )                                  AS "member_years",
        u."reputation",
        COALESCE(b."badge_count", 0)                                AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW."USERS" u
    CROSS JOIN cutoff c
    LEFT  JOIN "badge_counts"  b  ON u."id" = b."user_id"
    WHERE u."creation_date" <= c."cutoff_epoch_us"                  -- joined on/before 01-Oct-2021
)

/* 3.  aggregate by completed-year cohort */
SELECT
    "member_years",
    COUNT(*)                               AS "users_in_cohort",
    ROUND(AVG("reputation"), 4)            AS "avg_reputation",
    ROUND(AVG("badge_count"), 4)           AS "avg_badges"
FROM "user_cohorts"
GROUP BY "member_years"
ORDER BY "member_years";