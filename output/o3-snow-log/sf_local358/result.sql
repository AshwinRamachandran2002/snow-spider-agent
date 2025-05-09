/* Count of users by age category (20s, 30s, 40s, 50s, others) */
WITH user_age AS (
    SELECT
        "user_id",
        /* Convert birth_date to DATE and calculate the current age in years */
        CASE
            WHEN "birth_date" IS NULL OR TRIM("birth_date") = '' THEN NULL
            ELSE DATEDIFF(year, TO_DATE("birth_date"), CURRENT_DATE)
        END AS age
    FROM LOG.LOG.MST_USERS
),
age_buckets AS (
    SELECT
        CASE
            WHEN age BETWEEN 20 AND 29 THEN '20s'
            WHEN age BETWEEN 30 AND 39 THEN '30s'
            WHEN age BETWEEN 40 AND 49 THEN '40s'
            WHEN age BETWEEN 50 AND 59 THEN '50s'
            ELSE 'others'
        END AS age_category,
        COUNT(DISTINCT "user_id") AS user_count
    FROM user_age
    GROUP BY 1
)
SELECT
    age_category,
    user_count
FROM age_buckets
/* Put the named buckets first, then "others" */
ORDER BY
    CASE age_category
        WHEN '20s' THEN 1
        WHEN '30s' THEN 2
        WHEN '40s' THEN 3
        WHEN '50s' THEN 4
        ELSE 5
    END;