WITH criteria_users AS (
  SELECT "owner_user_id" AS "user_id", "id" AS "question_id"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS"
  WHERE "owner_user_id" IS NOT NULL
  
  UNION
  
  SELECT "a"."owner_user_id" AS "user_id", "q"."id" AS "question_id"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" AS "a"
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" AS "q"
    ON "q"."accepted_answer_id" = "a"."id"
  WHERE "a"."owner_user_id" IS NOT NULL
  
  UNION
  
  SELECT "owner_user_id" AS "user_id", "parent_id" AS "question_id"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS"
  WHERE "score" > 5 AND "owner_user_id" IS NOT NULL AND "parent_id" IS NOT NULL
  
  UNION
  
  SELECT "owner_user_id" AS "user_id", "parent_id" AS "question_id"
  FROM (
    SELECT "id", "owner_user_id", "parent_id", "score",
      ROW_NUMBER() OVER (PARTITION BY "parent_id" ORDER BY "score" DESC) AS "rank"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS"
    WHERE "owner_user_id" IS NOT NULL AND "parent_id" IS NOT NULL
  ) AS "ranked_answers"
  WHERE "ranked_answers"."rank" <= 3
  
  UNION
  
  SELECT "a"."owner_user_id" AS "user_id", "a"."parent_id" AS "question_id"
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" AS "a"
  JOIN (
    SELECT "parent_id", SUM("score") AS "total_score"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS"
    WHERE "score" IS NOT NULL AND "parent_id" IS NOT NULL
    GROUP BY "parent_id"
    HAVING SUM("score") > 0
  ) AS "t" ON "a"."parent_id" = "t"."parent_id"
  WHERE "a"."score" > 0.2 * "t"."total_score" AND "a"."owner_user_id" IS NOT NULL
),

user_question_views AS (
  SELECT DISTINCT "user_id", "question_id"
  FROM criteria_users
),

user_total_views AS (
  SELECT "uqv"."user_id", SUM("pq"."view_count") AS "total_view_count"
  FROM user_question_views AS "uqv"
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" AS "pq"
    ON "uqv"."question_id" = "pq"."id"
  WHERE "pq"."view_count" IS NOT NULL
  GROUP BY "uqv"."user_id"
),

final_data AS (
  SELECT "utv"."user_id", "u"."display_name" AS "user_display_name", "utv"."total_view_count"
  FROM user_total_views AS "utv"
  JOIN "STACKOVERFLOW"."STACKOVERFLOW"."USERS" AS "u"
    ON "utv"."user_id" = "u"."id"
)

SELECT "user_id", "user_display_name", "total_view_count"
FROM final_data
ORDER BY "total_view_count" DESC NULLS LAST
LIMIT 10;