SELECT
    t."gender",
    t."youngest_age",
    COUNT(CASE WHEN u."age" = t."youngest_age" THEN 1 END) AS "youngest_user_count",
    t."oldest_age",
    COUNT(CASE WHEN u."age" = t."oldest_age" THEN 1 END) AS "oldest_user_count"
FROM
    (
        SELECT
            "gender",
            MIN("age") AS "youngest_age",
            MAX("age") AS "oldest_age"
        FROM
            "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"
        GROUP BY
            "gender"
    ) t
JOIN
    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS" u
    ON t."gender" = u."gender"
GROUP BY
    t."gender",
    t."youngest_age",
    t."oldest_age";