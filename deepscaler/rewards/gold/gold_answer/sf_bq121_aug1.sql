-- Task: List the user ID and total number of badges for each of the first 100 Stack Overflow users who joined on or before October 1, 2021.
SELECT 
  "users"."id",
  SUM(CASE WHEN badges."user_id" IS NULL THEN 0 ELSE 1 END) AS "num_badges"
FROM "STACKOVERFLOW"."STACKOVERFLOW"."USERS" "users"
LEFT JOIN "STACKOVERFLOW"."STACKOVERFLOW"."BADGES" badges
  ON "users"."id" = badges."user_id"
WHERE CAST(TO_TIMESTAMP("users"."creation_date" / 1000000.0) AS DATE) <= DATE '2021-10-01'
GROUP BY "users"."id"
ORDER BY "users"."id"
LIMIT 100;