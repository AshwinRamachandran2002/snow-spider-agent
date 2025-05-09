SELECT "user_id", "tags"
FROM (
  SELECT 
    "owner_user_id" AS "user_id", 
    "tags", 
    TO_TIMESTAMP_NTZ("creation_date" / 1e6) AS "creation_date"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS"

  UNION ALL

  SELECT 
    a."owner_user_id" AS "user_id", 
    q."tags", 
    TO_TIMESTAMP_NTZ(a."creation_date" / 1e6) AS "creation_date"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" a
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
    ON a."parent_id" = q."id"

  UNION ALL

  SELECT 
    c."user_id", 
    q."tags", 
    TO_TIMESTAMP_NTZ(c."creation_date" / 1e6) AS "creation_date"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."COMMENTS" c
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
    ON c."post_id" = q."id"

  UNION ALL

  SELECT 
    c."user_id", 
    q."tags", 
    TO_TIMESTAMP_NTZ(c."creation_date" / 1e6) AS "creation_date"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."COMMENTS" c
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" a
    ON c."post_id" = a."id"
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
    ON a."parent_id" = q."id"
)
WHERE "user_id" BETWEEN 16712208 AND 18712208
  AND "creation_date" BETWEEN '2019-07-01' AND '2019-12-31'
LIMIT 100;