WITH "USER_AGE" AS (
    SELECT
        "user_id",
        /* calculate age; null if birth date is missing */
        CASE
            WHEN "birth_date" IS NOT NULL AND "birth_date" <> ''
            THEN DATEDIFF(year, TO_DATE("birth_date"), CURRENT_DATE)
            ELSE NULL
        END AS age
    FROM LOG.LOG."MST_USERS"
)
SELECT
    CASE
        WHEN age BETWEEN 20 AND 29 THEN '20s'
        WHEN age BETWEEN 30 AND 39 THEN '30s'
        WHEN age BETWEEN 40 AND 49 THEN '40s'
        WHEN age BETWEEN 50 AND 59 THEN '50s'
        ELSE 'others'
    END AS "age_category",
    COUNT(*) AS "user_count"
FROM "USER_AGE"
GROUP BY "age_category"
ORDER BY
    CASE "age_category"
        WHEN '20s' THEN 1
        WHEN '30s' THEN 2
        WHEN '40s' THEN 3
        WHEN '50s' THEN 4
        ELSE 5
    END NULLS LAST;