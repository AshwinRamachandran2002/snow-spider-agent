WITH badge_per_user AS (
    SELECT 
        "user_id",
        COUNT(*) AS "badge_count"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."BADGES"
    GROUP BY "user_id"
),
cut_off AS (                  -- constant cut-off date
    SELECT TO_TIMESTAMP_NTZ('2021-10-01') AS "cut_off"
)
SELECT
    FLOOR(
        DATEDIFF(
            'year',
            TO_TIMESTAMP(u."creation_date" / 1000000),   -- user join date
            c."cut_off"
        )
    )                                           AS "membership_years",
    AVG(u."reputation")                         AS "avg_reputation",
    AVG(COALESCE(b."badge_count", 0))           AS "avg_badges"
FROM "STACKOVERFLOW"."STACKOVERFLOW"."USERS" u
CROSS JOIN cut_off            c                -- provide the cut-off date
LEFT  JOIN badge_per_user     b ON u."id" = b."user_id"
WHERE TO_TIMESTAMP(u."creation_date" / 1000000) <= c."cut_off"   -- joined on/before 2021-10-01
GROUP BY "membership_years"
ORDER BY "membership_years";