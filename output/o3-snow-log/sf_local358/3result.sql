WITH users AS (
    SELECT
        "user_id",
        TRY_TO_DATE("birth_date") AS birth_date
    FROM LOG.LOG.MST_USERS
), age_calc AS (
    SELECT
        "user_id",
        CASE
            WHEN birth_date IS NOT NULL
                 THEN DATEDIFF('year', birth_date, CURRENT_DATE())
            ELSE NULL
        END AS age
    FROM users
), categorized AS (
    SELECT
        "user_id",
        CASE
            WHEN age BETWEEN 20 AND 29 THEN '20s'
            WHEN age BETWEEN 30 AND 39 THEN '30s'
            WHEN age BETWEEN 40 AND 49 THEN '40s'
            WHEN age BETWEEN 50 AND 59 THEN '50s'
            ELSE 'others'
        END AS age_category
    FROM age_calc
)
SELECT
    age_category,
    COUNT(DISTINCT "user_id") AS user_count
FROM categorized
GROUP BY age_category
ORDER BY
    CASE age_category
        WHEN '20s'  THEN 1
        WHEN '30s'  THEN 2
        WHEN '40s'  THEN 3
        WHEN '50s'  THEN 4
        ELSE 5
    END;