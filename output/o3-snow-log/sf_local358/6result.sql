WITH "USER_AGES" AS (
    SELECT
        "user_id",
        /* calculate age; will be NULL when birth_date is missing */
        CASE 
            WHEN "birth_date" IS NOT NULL 
            THEN DATEDIFF('year', TO_DATE("birth_date", 'YYYY-MM-DD'), CURRENT_DATE)
        END AS "age"
    FROM LOG.LOG.MST_USERS
)
SELECT
    CASE
        WHEN "age" BETWEEN 20 AND 29 THEN '20s'
        WHEN "age" BETWEEN 30 AND 39 THEN '30s'
        WHEN "age" BETWEEN 40 AND 49 THEN '40s'
        WHEN "age" BETWEEN 50 AND 59 THEN '50s'
        ELSE 'others'
    END AS "age_category",
    COUNT(DISTINCT "user_id") AS "user_count"
FROM "USER_AGES"
GROUP BY "age_category"
ORDER BY "age_category";