/* Users per age category (20s, 30s, 40s, 50s, others) */
WITH base AS (
    /* pick up every user and turn birth_date into DATE (NULL if blank) */
    SELECT
        "user_id",
        TRY_TO_DATE("birth_date")            AS birth_dt          -- TRY_TO_DATE returns NULL if the value is empty / invalid
    FROM LOG.LOG.MST_USERS
),
age_brackets AS (
    SELECT
        "user_id",
        CASE
            WHEN birth_dt IS NULL THEN 'others'
            ELSE
                CASE
                    WHEN DATEDIFF(year, birth_dt, CURRENT_DATE) BETWEEN 20 AND 29 THEN '20s'
                    WHEN DATEDIFF(year, birth_dt, CURRENT_DATE) BETWEEN 30 AND 39 THEN '30s'
                    WHEN DATEDIFF(year, birth_dt, CURRENT_DATE) BETWEEN 40 AND 49 THEN '40s'
                    WHEN DATEDIFF(year, birth_dt, CURRENT_DATE) BETWEEN 50 AND 59 THEN '50s'
                    ELSE 'others'
                END
        END                                                  AS age_category
    FROM base
)
SELECT
    age_category,
    COUNT(DISTINCT "user_id")      AS user_count
FROM age_brackets
GROUP BY age_category
ORDER BY age_category;