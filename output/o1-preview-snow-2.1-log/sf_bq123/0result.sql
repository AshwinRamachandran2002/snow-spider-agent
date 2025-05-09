SELECT
    sub."DayOfWeek" AS "Day",
    sub."Percentage"
FROM (
    SELECT
        DAYNAME(TO_TIMESTAMP(q."creation_date" / 1e6)) AS "DayOfWeek",
        ROUND(
            (
                COUNT(DISTINCT CASE WHEN ((a."creation_date" - q."creation_date") / 1e6) <= 3600 THEN q."id" END) * 100.0
            ) / COUNT(DISTINCT q."id")
            , 4
        ) AS "Percentage"
    FROM
        STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
    LEFT JOIN
        STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
        ON q."id" = a."parent_id"
    GROUP BY
        DAYNAME(TO_TIMESTAMP(q."creation_date" / 1e6))
) sub
ORDER BY
    sub."Percentage" DESC NULLS LAST
LIMIT 1 OFFSET 2;