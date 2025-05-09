SELECT
    "years_of_membership",
    ROUND(AVG("reputation"), 4) AS "Average_reputation",
    ROUND(AVG(COALESCE("badge_count", 0)), 4) AS "Average_number_of_badges"
FROM (
    SELECT
        u."id" AS "user_id",
        DATEDIFF('year', TO_TIMESTAMP_NTZ(u."creation_date" / 1e6), DATE '2021-10-01') AS "years_of_membership",
        u."reputation",
        COALESCE(b."badge_count", 0) AS "badge_count"
    FROM
        STACKOVERFLOW.STACKOVERFLOW.USERS u
    LEFT JOIN (
        SELECT
            "user_id",
            COUNT(*) AS "badge_count"
        FROM
            STACKOVERFLOW.STACKOVERFLOW.BADGES
        GROUP BY
            "user_id"
    ) b ON u."id" = b."user_id"
    WHERE
        u."creation_date" <= 1633046400000000  -- October 1, 2021 in microseconds
) sub
GROUP BY
    "years_of_membership"
ORDER BY
    "years_of_membership" ASC;