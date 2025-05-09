WITH user_question AS (
    -- Users who own a question
    SELECT "owner_user_id" AS "user_id", "id" AS "question_id"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
    WHERE "owner_user_id" IS NOT NULL AND "id" IS NOT NULL

    UNION

    -- Users who provided an accepted answer
    SELECT a."owner_user_id" AS "user_id", q."id" AS "question_id"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
    JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a ON q."accepted_answer_id" = a."id"
    WHERE a."owner_user_id" IS NOT NULL AND q."id" IS NOT NULL

    UNION

    -- Users who have an answer with a score above 5
    SELECT "owner_user_id" AS "user_id", "parent_id" AS "question_id"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    WHERE "score" > 5 AND "owner_user_id" IS NOT NULL AND "parent_id" IS NOT NULL

    UNION

    -- Users who rank in the top 3 answers for a question
    SELECT "owner_user_id" AS "user_id", "parent_id" AS "question_id"
    FROM (
        SELECT "id", "parent_id", "owner_user_id", ROW_NUMBER() OVER (PARTITION BY "parent_id" ORDER BY "score" DESC) AS "rank"
        FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
        WHERE "owner_user_id" IS NOT NULL AND "parent_id" IS NOT NULL
    ) ranked_answers
    WHERE "rank" <= 3

    UNION

    -- Users who have an answer with a score over 20% of the total answer score for that question
    SELECT a."owner_user_id" AS "user_id", a."parent_id" AS "question_id"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
    JOIN (
        SELECT "parent_id", SUM("score") AS "total_score"
        FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
        WHERE "parent_id" IS NOT NULL
        GROUP BY "parent_id"
    ) t ON a."parent_id" = t."parent_id"
    WHERE a."score" > 0.2 * t."total_score" AND a."owner_user_id" IS NOT NULL AND a."parent_id" IS NOT NULL
),

unique_user_question AS (
    SELECT DISTINCT "user_id", "question_id"
    FROM user_question
    WHERE "user_id" IS NOT NULL AND "question_id" IS NOT NULL
)

SELECT u."id" AS "user_id", u."display_name" AS "user_display_name", SUM(q."view_count") AS "total_view_count"
FROM unique_user_question uq
JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q ON uq."question_id" = q."id"
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u ON uq."user_id" = u."id"
GROUP BY u."id", u."display_name"
ORDER BY SUM(q."view_count") DESC NULLS LAST
LIMIT 10;