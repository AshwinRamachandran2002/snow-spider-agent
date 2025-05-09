WITH "USER_AGE" AS (
    SELECT
        "user_id",
        /* exact age at today */
        DATEDIFF(
            year,
            TO_DATE("birth_date", 'YYYY-MM-DD'),
            CURRENT_DATE()
        )
        /* adjust if birthday has not yet occurred this year */
        - CASE 
            WHEN TO_CHAR(CURRENT_DATE(), 'MMDD') < TO_CHAR(TO_DATE("birth_date", 'YYYY-MM-DD'), 'MMDD') 
              THEN 1 
              ELSE 0 
          END AS "age"
    FROM LOG.LOG.MST_USERS
    WHERE "birth_date" IS NOT NULL AND "birth_date" <> ''
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
FROM "USER_AGE"
GROUP BY 1
ORDER BY
    CASE 
        WHEN "age_category" = '20s' THEN 1
        WHEN "age_category" = '30s' THEN 2
        WHEN "age_category" = '40s' THEN 3
        WHEN "age_category" = '50s' THEN 4
        ELSE 5
    END;