WITH total_answer_scores AS (
    SELECT "parent_id" AS "question_id", SUM("score") AS "total_score"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    GROUP BY "parent_id"
),
question_owner AS (
    SELECT "owner_user_id" AS "user_id", "id" AS "question_id"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
    WHERE "owner_user_id" IS NOT NULL
),
accepted_answer_owner AS (
    SELECT a."owner_user_id" AS "user_id", q."id" AS "question_id"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
      ON q."accepted_answer_id" = a."id"
    WHERE a."owner_user_id" IS NOT NULL
),
answers_score_gt5 AS (
    SELECT "owner_user_id" AS "user_id", "parent_id" AS "question_id"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    WHERE "score" > 5 AND "owner_user_id" IS NOT NULL
),
answers_score_gt_20pct AS (
    SELECT a."owner_user_id" AS "user_id", a."parent_id" AS "question_id"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    JOIN total_answer_scores s ON a."parent_id" = s."question_id"
    WHERE a."score" > 0
      AND s."total_score" > 0
      AND a."score" > 0.2 * s."total_score"
      AND a."owner_user_id" IS NOT NULL
),
top3_answers AS (
    SELECT "user_id", "question_id"
    FROM (
        SELECT "owner_user_id" AS "user_id", "parent_id" AS "question_id",
               RANK() OVER (PARTITION BY "parent_id" ORDER BY "score" DESC) AS rnk
        FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
        WHERE "owner_user_id" IS NOT NULL
    ) sub
    WHERE rnk <= 3
),
all_associations AS (
    SELECT * FROM question_owner
    UNION
    SELECT * FROM accepted_answer_owner
    UNION
    SELECT * FROM answers_score_gt5
    UNION
    SELECT * FROM answers_score_gt_20pct
    UNION
    SELECT * FROM top3_answers
),
user_question_viewcounts AS (
    SELECT a."user_id", a."question_id", q."view_count"
    FROM all_associations a
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q ON a."question_id" = q."id"
),
user_total_viewcounts AS (
    SELECT "user_id", SUM("view_count") AS "combined_view_count"
    FROM user_question_viewcounts
    GROUP BY "user_id"
)
SELECT "user_id", "combined_view_count"
FROM user_total_viewcounts
ORDER BY "combined_view_count" DESC NULLS LAST
LIMIT 10;