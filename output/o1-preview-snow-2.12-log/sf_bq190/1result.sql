WITH age_stats AS (
    SELECT
        "gender",
        MIN("age") AS "Min_Age",
        MAX("age") AS "Max_Age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE
        "gender" IN ('M', 'F') AND
        TO_TIMESTAMP_LTZ("created_at", 6) BETWEEN TO_TIMESTAMP('2019-01-01', 'YYYY-MM-DD')
                                               AND TO_TIMESTAMP('2022-04-30', 'YYYY-MM-DD')
    GROUP BY "gender"
),
min_age_counts AS (
    SELECT
        u."gender",
        COUNT(*) AS "Users_with_Min_Age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
    JOIN age_stats ON u."gender" = age_stats."gender" AND u."age" = age_stats."Min_Age"
    WHERE
        TO_TIMESTAMP_LTZ(u."created_at", 6) BETWEEN TO_TIMESTAMP('2019-01-01', 'YYYY-MM-DD')
                                                   AND TO_TIMESTAMP('2022-04-30', 'YYYY-MM-DD')
    GROUP BY u."gender"
),
max_age_counts AS (
    SELECT
        u."gender",
        COUNT(*) AS "Users_with_Max_Age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
    JOIN age_stats ON u."gender" = age_stats."gender" AND u."age" = age_stats."Max_Age"
    WHERE
        TO_TIMESTAMP_LTZ(u."created_at", 6) BETWEEN TO_TIMESTAMP('2019-01-01', 'YYYY-MM-DD')
                                                   AND TO_TIMESTAMP('2022-04-30', 'YYYY-MM-DD')
    GROUP BY u."gender"
)
SELECT
    CASE WHEN age_stats."gender" = 'M' THEN 'Male' ELSE 'Female' END AS "Gender",
    age_stats."Min_Age",
    min_age_counts."Users_with_Min_Age",
    age_stats."Max_Age",
    max_age_counts."Users_with_Max_Age"
FROM age_stats
LEFT JOIN min_age_counts ON age_stats."gender" = min_age_counts."gender"
LEFT JOIN max_age_counts ON age_stats."gender" = max_age_counts."gender"
ORDER BY "Gender";