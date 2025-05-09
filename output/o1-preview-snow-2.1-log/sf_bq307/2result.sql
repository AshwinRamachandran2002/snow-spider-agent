WITH FirstGoldBadges AS (
    SELECT
        B."user_id",
        B."name" AS "Badge_Name",
        B."date"
    FROM
        "STACKOVERFLOW"."STACKOVERFLOW"."BADGES" B
    JOIN (
        SELECT
            "user_id",
            MIN("date") AS "first_gold_badge_date"
        FROM
            "STACKOVERFLOW"."STACKOVERFLOW"."BADGES"
        WHERE
            "class" = 1
        GROUP BY
            "user_id"
    ) FG ON B."user_id" = FG."user_id" AND B."date" = FG."first_gold_badge_date"
    WHERE
        B."class" = 1
)
SELECT
    FG."Badge_Name",
    COUNT(DISTINCT FG."user_id") AS "Number_of_Users",
    ROUND(AVG((FG."date" - U."creation_date") / 86400000000.0), 4) AS "Average_Days_From_Account_Creation"
FROM
    FirstGoldBadges FG
JOIN
    "STACKOVERFLOW"."STACKOVERFLOW"."USERS" U ON FG."user_id" = U."id"
GROUP BY
    FG."Badge_Name"
ORDER BY
    COUNT(DISTINCT FG."user_id") DESC NULLS LAST, FG."Badge_Name"
LIMIT 10;