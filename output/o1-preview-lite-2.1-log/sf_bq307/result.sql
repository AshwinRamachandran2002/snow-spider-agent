SELECT first_gold_badges."name" AS "Badge_Name",
       COUNT(*) AS "Number_of_Users",
       ROUND(AVG(first_gold_badges."days_to_badge"), 4) AS "Average_Days_From_Account_Creation"
FROM (
    SELECT b."user_id", b."name", 
           DATEDIFF('day', TO_TIMESTAMP_LTZ(u."creation_date" / 1000000), TO_TIMESTAMP_LTZ(b."date" / 1000000)) AS "days_to_badge"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b
    JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u ON b."user_id" = u."id"
    WHERE b."class" = 1
      AND b."date" = (
          SELECT MIN(b2."date")
          FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b2
          WHERE b2."user_id" = b."user_id" AND b2."class" = 1
      )
) AS first_gold_badges
GROUP BY first_gold_badges."name"
ORDER BY "Number_of_Users" DESC NULLS LAST
LIMIT 10;