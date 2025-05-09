WITH FirstGoldBadges AS (
  SELECT
    b."user_id",
    b."name",
    b."date",
    u."creation_date",
    ((b."date" - u."creation_date") / 86400000000.0) AS "days_to_badge",
    ROW_NUMBER() OVER (PARTITION BY b."user_id" ORDER BY b."date", b."id") AS rn
  FROM STACKOVERFLOW.STACKOVERFLOW."BADGES" b
  JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" u ON b."user_id" = u."id"
  WHERE b."class" = 1
)
SELECT
  "name" AS "Badge_Name",
  COUNT(*) AS "Number_of_Users",
  ROUND(AVG("days_to_badge"), 4) AS "Average_Days_From_Account_Creation"
FROM FirstGoldBadges
WHERE rn = 1
GROUP BY "name"
ORDER BY "Number_of_Users" DESC NULLS LAST
LIMIT 10;