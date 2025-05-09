/* Count the number of users in each age group (20s, 30s, 40s, 50s, others) */
SELECT
    "age_group",
    COUNT(DISTINCT "user_id") AS "user_count"
FROM (
    SELECT
        "user_id",
        CASE
            WHEN age BETWEEN 20 AND 29 THEN '20s'
            WHEN age BETWEEN 30 AND 39 THEN '30s'
            WHEN age BETWEEN 40 AND 49 THEN '40s'
            WHEN age BETWEEN 50 AND 59 THEN '50s'
            ELSE 'others'
        END AS "age_group"
    FROM (
        SELECT
            "user_id",
            DATEDIFF(year, TO_DATE("birth_date"), CURRENT_DATE()) AS age
        FROM LOG.LOG.MST_USERS
    )
)
GROUP BY "age_group"
ORDER BY "age_group";