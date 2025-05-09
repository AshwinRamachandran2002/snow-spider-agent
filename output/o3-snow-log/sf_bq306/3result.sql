WITH answers AS (
    SELECT 
        "id"         AS answer_id,
        "parent_id"  AS question_id
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    WHERE "owner_user_id" = 1908967
      AND "creation_date" < 1528329600000000            -- 2018-06-07
), votes_per_answer AS (
    SELECT
        "post_id"                                                           AS answer_id,
        SUM(CASE WHEN "vote_type_id" = 2 THEN 1 ELSE 0 END)                AS upvotes,
        SUM(CASE WHEN "vote_type_id" = 1 THEN 1 ELSE 0 END)                AS accepts
    FROM STACKOVERFLOW.STACKOVERFLOW."VOTES"
    WHERE "vote_type_id" IN (1, 2)
    GROUP BY "post_id"
), scored_answers AS (
    SELECT
        a.answer_id,
        a.question_id,
        COALESCE(10 * v.upvotes, 0) + COALESCE(15 * v.accepts, 0)           AS score
    FROM answers a
    LEFT JOIN votes_per_answer v ON v.answer_id = a.answer_id
), question_tags AS (
    SELECT
        sa.score,
        tag.value::STRING                                                   AS tag_name
    FROM scored_answers sa
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
      ON q."id" = sa.question_id
    , LATERAL FLATTEN(INPUT => SPLIT(q."tags", '|')) tag
)
SELECT
    tag_name       AS "TAG",
    SUM(score)     AS "TOTAL_SCORE"
FROM question_tags
GROUP BY tag_name
ORDER BY "TOTAL_SCORE" DESC NULLS LAST
LIMIT 10;