WITH
new_users AS (
    SELECT
        u."id" AS "user_id",
        u."creation_date",
        TO_CHAR(TO_TIMESTAMP_NTZ(u."creation_date"/1e6), 'YYYY-MM') AS "Month"
    FROM
        STACKOVERFLOW.STACKOVERFLOW.USERS u
    WHERE
        u."creation_date" BETWEEN 1609459200000000 AND 1640995199999999
),
user_activity AS (
    SELECT
        n."user_id",
        n."Month",
        MAX(CASE WHEN q."id" IS NOT NULL THEN 1 ELSE 0 END) AS "Asked_Question",
        MAX(CASE WHEN a."id" IS NOT NULL AND (a."creation_date" - n."creation_date") <= 2592000000000 THEN 1 ELSE 0 END) AS "Answered_Within_30_Days"
    FROM
        new_users n
        LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q ON n."user_id" = q."owner_user_id"
        LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a ON n."user_id" = a."owner_user_id"
    GROUP BY
        n."user_id",
        n."Month"
)
SELECT
    ua."Month",
    COUNT(*) AS "New_Users",
    ROUND(COUNT(CASE WHEN ua."Asked_Question" = 1 THEN 1 END) * 100.0 / COUNT(*), 4) AS "Percentage_Asked_Questions",
    ROUND(COUNT(CASE WHEN ua."Asked_Question" = 1 AND ua."Answered_Within_30_Days" = 1 THEN 1 END) * 100.0 / COUNT(*), 4) AS "Percentage_Asked_And_Answered_Within_30_Days"
FROM
    user_activity ua
GROUP BY
    ua."Month"
ORDER BY
    ua."Month";