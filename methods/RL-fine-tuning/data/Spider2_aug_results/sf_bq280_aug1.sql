-- Task: Provide the display names and the number of answers posted by users with reputation greater than 10. Limit the results to 100 entries.
SELECT "USERS"."display_name", COUNT("POSTS_ANSWERS"."id") AS "answer_count"
FROM STACKOVERFLOW.STACKOVERFLOW.USERS
JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
  ON "USERS"."id" = "POSTS_ANSWERS"."owner_user_id"
WHERE "USERS"."reputation" > 10
GROUP BY "USERS"."id", "USERS"."display_name"
LIMIT 100;