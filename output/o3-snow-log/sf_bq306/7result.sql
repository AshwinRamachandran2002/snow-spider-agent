WITH answers AS (
    SELECT 
        a."id"          AS answer_id,
        a."parent_id"   AS question_id
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    WHERE a."owner_user_id" = 1908967
      AND a."creation_date" < 1528329600000000        -- 2018-06-07 00:00:00 UTC in µs
), 
votes AS (
    SELECT 
        v."post_id",
        SUM(CASE WHEN v."vote_type_id" = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN v."vote_type_id" = 1 THEN 1 ELSE 0 END) AS accepted_votes
    FROM STACKOVERFLOW.STACKOVERFLOW."VOTES" v
    JOIN answers a ON a.answer_id = v."post_id"
    GROUP BY v."post_id"
), 
answer_scores AS (
    SELECT
        a.answer_id,
        a.question_id,
        COALESCE(v.upvotes,0)        AS upvotes,
        COALESCE(v.accepted_votes,0) AS accepted_votes,
        COALESCE(v.upvotes,0)*10 + COALESCE(v.accepted_votes,0)*15 AS score
    FROM answers a
    LEFT JOIN votes v ON v."post_id" = a.answer_id
), 
question_tags AS (
    SELECT
        q."id" AS question_id,
        TRIM(tag.value) AS tag
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q,
         LATERAL FLATTEN(input => SPLIT(q."tags",'|')) tag
)
SELECT
    qt.tag,
    SUM(ascore.score) AS total_score
FROM answer_scores ascore
JOIN question_tags qt
  ON qt.question_id = ascore.question_id
GROUP BY qt.tag
ORDER BY total_score DESC NULLS LAST
LIMIT 10;