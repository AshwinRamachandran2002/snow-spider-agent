WITH user_answers AS (
    SELECT "id", "parent_id"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS"
    WHERE "owner_user_id" = 1908967 AND "creation_date" < 1528329600000000
),
answer_votes AS (
    SELECT "post_id",
        SUM(CASE WHEN "vote_type_id" = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN "vote_type_id" = 1 THEN 1 ELSE 0 END) AS accepted_answers
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."VOTES"
    WHERE "post_id" IN (SELECT "id" FROM user_answers)
    GROUP BY "post_id"
),
answer_scores AS (
    SELECT av."post_id",
        (10 * av.upvotes) + (15 * av.accepted_answers) AS total_score
    FROM answer_votes av
),
answer_tags AS (
    SELECT ua."id" AS "answer_id", ua."parent_id" AS "question_id", pq."tags"
    FROM user_answers ua
    JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" pq
    ON ua."parent_id" = pq."id"
),
tags_exploded AS (
    SELECT at."answer_id", at."question_id", ascore.total_score,
           REGEXP_REPLACE(t.value, '^<|>$', '') AS tag
    FROM answer_tags at
    JOIN answer_scores ascore ON at."answer_id" = ascore."post_id",
    LATERAL FLATTEN(INPUT => SPLIT(REGEXP_REPLACE(at."tags", '^<|>$', ''), '><')) AS t
),
tag_scores AS (
    SELECT tag, SUM(total_score) AS total_score
    FROM tags_exploded
    GROUP BY tag
)
SELECT tag, total_score
FROM tag_scores
ORDER BY total_score DESC NULLS LAST
LIMIT 10;