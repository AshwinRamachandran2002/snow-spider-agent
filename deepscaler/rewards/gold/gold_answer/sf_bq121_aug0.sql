-- Task: For Stack Overflow users who joined on or before October 1, 2021, calculate the number of full years of membership (tenure) for each user by computing the difference in years between their creation date and October 1, 2021. Then, group the users by their tenure and determine, for each group, the total number of users, the average reputation, and the average number of badges.

WITH sub AS (
  SELECT 
    "users"."id",
    CAST(TO_TIMESTAMP(MAX("users"."creation_date") / 1000000.0) AS DATE) AS "user_creation_date",  -- Use MAX aggregate on creation_date and convert to DATE
    MAX("users"."reputation") AS "reputation",  
    SUM(CASE WHEN badges."user_id" IS NULL THEN 0 ELSE 1 END) AS "num_badges"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."USERS" "users"
  LEFT JOIN "STACKOVERFLOW"."STACKOVERFLOW"."BADGES" badges
    ON "users"."id" = badges."user_id"
  WHERE CAST(TO_TIMESTAMP("users"."creation_date" / 1000000.0) AS DATE) <= DATE '2021-10-01'
  GROUP BY "users"."id"
)

SELECT 
  DATEDIFF(YEAR, "user_creation_date", DATE '2021-10-01') AS "user_tenure",
  COUNT(1) AS "Num_Users",
  AVG("reputation") AS "Avg_Reputation",
  AVG("num_badges") AS "Avg_Num_Badges"
FROM sub
GROUP BY "user_tenure"
ORDER BY "user_tenure";