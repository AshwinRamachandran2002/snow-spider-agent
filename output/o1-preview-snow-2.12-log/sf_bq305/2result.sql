SELECT assoc."user_id" AS "User_ID", SUM(assoc."view_count") AS "Combined_View_Count"
FROM (
    SELECT DISTINCT "user_id", "question_id", "view_count"
    FROM (
        -- Criterion 1: User owns the question
        SELECT pq."owner_user_id" AS "user_id", pq."id" AS "question_id", pq."view_count"
        FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS pq
        WHERE pq."owner_user_id" IS NOT NULL

        UNION ALL

        -- Criterion 2: User has the accepted answer to a question
        SELECT pa."owner_user_id" AS "user_id", pq."id" AS "question_id", pq."view_count"
        FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS pq
        JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS pa
            ON pq."accepted_answer_id" = pa."id"
        WHERE pq."accepted_answer_id" IS NOT NULL AND pa."owner_user_id" IS NOT NULL

        UNION ALL

        -- Criterion 3: User has an answer with score greater than 5
        SELECT pa."owner_user_id" AS "user_id", pa."parent_id" AS "question_id", pq."view_count"
        FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS pa
        JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS pq
            ON pa."parent_id" = pq."id"
        WHERE pa."score" > 5

        UNION ALL

        -- Criterion 4: User's answer's score exceeds 20% of total answer scores for the question
        SELECT pa."owner_user_id" AS "user_id", pa."parent_id" AS "question_id", pq."view_count"
        FROM (
            SELECT a."id", a."parent_id", a."owner_user_id", a."score"
            FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
            JOIN (
                SELECT "parent_id", SUM("score") AS total_score
                FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
                GROUP BY "parent_id"
            ) t ON a."parent_id" = t."parent_id"
            WHERE a."score" > 0.2 * t.total_score AND a."score" > 0
        ) pa
        JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS pq
            ON pa."parent_id" = pq."id"

        UNION ALL

        -- Criterion 5: User's answer is among the top three highest-scoring answers for the question
        SELECT pa."owner_user_id" AS "user_id", pa."parent_id" AS "question_id", pq."view_count"
        FROM (
            SELECT "id", "parent_id", "owner_user_id", "score",
                ROW_NUMBER() OVER (PARTITION BY "parent_id" ORDER BY "score" DESC) AS "rank"
            FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
        ) pa
        JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS pq
            ON pa."parent_id" = pq."id"
        WHERE pa."rank" <= 3
    ) sub
) assoc
WHERE assoc."user_id" IS NOT NULL
GROUP BY assoc."user_id"
ORDER BY "Combined_View_Count" DESC NULLS LAST
LIMIT 10;