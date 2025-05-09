WITH "USER_CREATION" AS (                -- each user's account‑creation moment
    SELECT
        "id"            AS "USER_ID",
        "creation_date" AS "CREATION_DATE"
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS
),

"FIRST_GOLD" AS (                        -- the very first gold badge each user earned
    SELECT
        b."user_id"                 AS "USER_ID",
        b."name"                    AS "BADGE_NAME",
        b."date"                    AS "BADGE_DATE",
        ROW_NUMBER() OVER (PARTITION BY b."user_id"
                           ORDER BY b."date", b."id") AS "RN"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b
    WHERE b."class" = 1                     -- gold badges only
    QUALIFY "RN" = 1                        -- keep the earliest gold badge per user
),

"DIFFS" AS (                               -- days from account creation to first gold
    SELECT
        fg."BADGE_NAME",
        DATEDIFF(
            'day',
            TO_TIMESTAMP(uc."CREATION_DATE" / 1000000),   -- account creation
            TO_TIMESTAMP(fg."BADGE_DATE"   / 1000000)     -- badge award
        ) AS "DAYS_TO_BADGE"
    FROM "FIRST_GOLD" fg
    JOIN "USER_CREATION" uc
          ON fg."USER_ID" = uc."USER_ID"
)

SELECT
    "BADGE_NAME",
    COUNT(*)                         AS "USER_COUNT",
    AVG("DAYS_TO_BADGE")             AS "AVG_DAYS_TO_FIRST_GOLD_BADGE"
FROM "DIFFS"
GROUP BY "BADGE_NAME"
ORDER BY "USER_COUNT" DESC NULLS LAST, "BADGE_NAME"
LIMIT 10;