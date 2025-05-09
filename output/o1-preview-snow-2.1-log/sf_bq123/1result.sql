SELECT
    sub."Day",
    ROUND(sub."Percentage", 4) AS "Percentage"
FROM (
    SELECT
        DAYNAME(TO_TIMESTAMP_LTZ("q"."creation_date" / 1000000)) AS "Day",
        (COUNT(CASE WHEN ("a"."min_creation_date" IS NOT NULL) AND (("a"."min_creation_date" - "q"."creation_date") <= 3600 * 1000000) THEN 1 END) * 100.0) / COUNT(*) AS "Percentage"
    FROM
        "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" AS "q"
    LEFT JOIN (
        SELECT
            "parent_id",
            MIN("creation_date") AS "min_creation_date"
        FROM
            "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS"
        GROUP BY
            "parent_id"
        ) AS "a" ON "q"."id" = "a"."parent_id"
    GROUP BY
        DAYNAME(TO_TIMESTAMP_LTZ("q"."creation_date" / 1000000))
    ) AS sub
ORDER BY
    sub."Percentage" DESC NULLS LAST,
    sub."Day"
LIMIT 1
OFFSET 2;