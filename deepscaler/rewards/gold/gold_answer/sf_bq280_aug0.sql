-- Task: Find the display name of the user with reputation greater than 10 who has posted the most answers on Stack Overflow.

SELECT "USERS"."display_name"
FROM STACKOVERFLOW.STACKOVERFLOW.USERS
JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
  ON "USERS"."id" = "POSTS_ANSWERS"."owner_user_id"
WHERE "USERS"."reputation" > 10
GROUP BY "USERS"."id", "USERS"."display_name"
ORDER BY COUNT("POSTS_ANSWERS"."id") DESC NULLS LAST
LIMIT 1;