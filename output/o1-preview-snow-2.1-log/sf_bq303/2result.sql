SELECT "User_ID", "Tags"
FROM (
  SELECT
    "owner_user_id" AS "User_ID",
    "tags" AS "Tags",
    "creation_date" AS "creation_timestamp"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS"

  UNION ALL

  SELECT
    "a"."owner_user_id" AS "User_ID",
    "q"."tags" AS "Tags",
    "a"."creation_date" AS "creation_timestamp"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" AS "a"
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" AS "q"
    ON "a"."parent_id" = "q"."id"

  UNION ALL

  SELECT
    "c"."user_id" AS "User_ID",
    "q"."tags" AS "Tags",
    "c"."creation_date" AS "creation_timestamp"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."COMMENTS" AS "c"
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" AS "q"
    ON "c"."post_id" = "q"."id"

  UNION ALL

  SELECT
    "c"."user_id" AS "User_ID",
    "q"."tags" AS "Tags",
    "c"."creation_date" AS "creation_timestamp"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."COMMENTS" AS "c"
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" AS "a"
    ON "c"."post_id" = "a"."id"
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" AS "q"
    ON "a"."parent_id" = "q"."id"
) AS "combined"
WHERE
  "User_ID" BETWEEN 16712208 AND 18712208
  AND "creation_timestamp" BETWEEN 1561939200000000 AND 1577836799000000;