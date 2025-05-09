WITH badge_counts AS (
    SELECT "user_id", COUNT(*) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
)
SELECT
    DATEDIFF('year', TO_TIMESTAMP("creation_date" / 1e6), TO_DATE('2021-10-01')) AS "Years_of_membership",
    ROUND(AVG("reputation"), 4) AS "Average_reputation",
    ROUND(AVG(COALESCE(badge_counts."badge_count", 0)), 4) AS "Average_number_of_badges"
FROM
    STACKOVERFLOW.STACKOVERFLOW.USERS
LEFT JOIN
    badge_counts
ON
    STACKOVERFLOW.STACKOVERFLOW.USERS."id" = badge_counts."user_id"
WHERE
    "creation_date" <= 1633046400000000  -- October 1, 2021 in microseconds since epoch
GROUP BY
    "Years_of_membership"
ORDER BY
    "Years_of_membership";