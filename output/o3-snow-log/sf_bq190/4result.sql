WITH filtered_users AS (
    -- users who signed-up between 1-Jan-2019 and 30-Apr-2022 (timestamps in micro-seconds)
    SELECT "id",
           "gender",
           "age"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE  "created_at" BETWEEN 1546300800000000 AND 1651363199000000
),
age_limits AS (
    -- youngest (min age) and oldest (max age) per gender within the period
    SELECT  "gender",
            MIN("age") AS "min_age",
            MAX("age") AS "max_age"
    FROM    filtered_users
    GROUP BY "gender"
)
SELECT
       CASE
           WHEN fu."age" = al."min_age" THEN 'youngest'
           ELSE 'oldest'
       END                                    AS "age_group",
       fu."gender",
       fu."age",
       COUNT(*)                               AS "users_in_group"
FROM   filtered_users fu
JOIN   age_limits al
       ON fu."gender" = al."gender"
      AND (fu."age" = al."min_age"
           OR fu."age" = al."max_age")
GROUP BY
       CASE WHEN fu."age" = al."min_age" THEN 'youngest' ELSE 'oldest' END,
       fu."gender",
       fu."age"
ORDER BY
       fu."gender",
       "age_group";