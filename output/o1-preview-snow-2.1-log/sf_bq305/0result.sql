WITH "user_question_pairs" AS (

  -- Users who own a question
  SELECT DISTINCT q."owner_user_id" AS "user_id", q."id" AS "question_id"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
  WHERE q."owner_user_id" IS NOT NULL

  UNION

  -- Users who provided an accepted answer
  SELECT DISTINCT a."owner_user_id" AS "user_id", q."id" AS "question_id"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" a
    ON q."accepted_answer_id" = a."id"
  WHERE a."owner_user_id" IS NOT NULL

  UNION

  -- Users who have an answer with a score above 5
  SELECT DISTINCT a."owner_user_id" AS "user_id", a."parent_id" AS "question_id"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" a
  WHERE a."score" > 5 AND a."owner_user_id" IS NOT NULL

  UNION

  -- Users whose answer ranks in the top 3 for a question
  SELECT DISTINCT ra."owner_user_id" AS "user_id", ra."parent_id" AS "question_id"
  FROM (
    SELECT
      a."id",
      a."owner_user_id",
      a."parent_id",
      RANK() OVER (PARTITION BY a."parent_id" ORDER BY a."score" DESC) AS "rank"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" a
    WHERE a."owner_user_id" IS NOT NULL
  ) ra
  WHERE ra."rank" <= 3

  UNION

  -- Users who have an answer with a score over 20% of the total answer score for that question
  SELECT DISTINCT a."owner_user_id" AS "user_id", a."parent_id" AS "question_id"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" a
  JOIN (
    SELECT
      "parent_id",
      SUM("score") AS "total_score"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS"
    WHERE "parent_id" IS NOT NULL
    GROUP BY "parent_id"
  ) ts
    ON a."parent_id" = ts."parent_id"
  WHERE a."score" > 0.2 * ts."total_score" AND a."owner_user_id" IS NOT NULL

)

SELECT
  u."id" AS "user_id",
  u."display_name" AS "user_display_name",
  SUM(q."view_count") AS "total_view_count"
FROM "user_question_pairs" up
JOIN "STACKOVERFLOW"."STACKOVERFLOW"."USERS" u
  ON up."user_id" = u."id"
JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
  ON up."question_id" = q."id"
GROUP BY u."id", u."display_name"
ORDER BY "total_view_count" DESC
LIMIT 10;