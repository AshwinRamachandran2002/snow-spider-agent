SELECT
    a."id" AS "answer_id",
    COALESCE(u_answerer."reputation", 0) AS "answerer_reputation",
    a."score" AS "answer_score",
    COALESCE(a."comment_count", 0) AS "answer_comment_count",
    q."tags" AS "question_tags",
    q."score" AS "question_score",
    COALESCE(q."answer_count", 0) AS "question_answer_count",
    COALESCE(u_asker."reputation", 0) AS "asker_reputation",
    COALESCE(q."view_count", 0) AS "question_view_count",
    COALESCE(q."comment_count", 0) AS "question_comment_count"
FROM
    "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" q
INNER JOIN
    "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" a
    ON q."accepted_answer_id" = a."id"
LEFT JOIN
    "STACKOVERFLOW"."STACKOVERFLOW"."USERS" u_asker
    ON q."owner_user_id" = u_asker."id"
LEFT JOIN
    "STACKOVERFLOW"."STACKOVERFLOW"."USERS" u_answerer
    ON a."owner_user_id" = u_answerer."id"
WHERE
    TO_TIMESTAMP(q."creation_date" / 1000000) >= '2016-01-01' AND
    TO_TIMESTAMP(q."creation_date" / 1000000) < '2016-02-01' AND
    q."tags" ILIKE '%javascript%' AND (
        q."tags" ILIKE '%xss%' OR
        q."tags" ILIKE '%cross-site-scripting%' OR
        q."tags" ILIKE '%security%' OR
        q."tags" ILIKE '%exploit%' OR
        q."tags" ILIKE '%cybersecurity%'
    ) AND
    q."accepted_answer_id" IS NOT NULL;