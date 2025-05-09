WITH last_activity AS (
    SELECT 
        "by",
        MAX("time") AS last_activity_time,
        MAX(EXTRACT(YEAR FROM TO_TIMESTAMP("time")) * 100 + EXTRACT(MONTH FROM TO_TIMESTAMP("time"))) AS last_active_year_month
    FROM HACKER_NEWS.HACKER_NEWS.FULL
    WHERE "by" IS NOT NULL AND "time" <= 1725926400
    GROUP BY "by"
), activity_after AS (
    SELECT DISTINCT f."by"
    FROM HACKER_NEWS.HACKER_NEWS.FULL f
    INNER JOIN last_activity la
        ON f."by" = la."by"
    WHERE 
        f."time" <= 1725926400
        AND (EXTRACT(YEAR FROM TO_TIMESTAMP(f."time")) * 100 + EXTRACT(MONTH FROM TO_TIMESTAMP(f."time"))) > la.last_active_year_month
), inactive_users AS (
    SELECT la."by", la.last_activity_time, la.last_active_year_month
    FROM last_activity la
    LEFT JOIN activity_after aa
        ON la."by" = aa."by"
    WHERE aa."by" IS NULL
), highest_inactive_users AS (
    SELECT "by", last_activity_time
    FROM inactive_users
    WHERE last_active_year_month = (SELECT MAX(last_active_year_month) FROM inactive_users)
)
SELECT TOP 1 f."id" AS "ID", EXTRACT(MONTH FROM TO_TIMESTAMP(f."time")) AS "Last_active_month"
FROM HACKER_NEWS.HACKER_NEWS.FULL f
INNER JOIN highest_inactive_users hiu
    ON f."by" = hiu."by" AND f."time" = hiu.last_activity_time
ORDER BY f."time" DESC NULLS LAST;