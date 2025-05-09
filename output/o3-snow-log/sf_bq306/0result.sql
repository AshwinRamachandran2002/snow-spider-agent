WITH answers AS (   -- all answers by the user before 7 Jun 2018
    SELECT  a."id"          AS answer_id ,
            a."parent_id"   AS question_id
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    WHERE   a."owner_user_id" = 1908967
      AND   TO_TIMESTAMP_NTZ(a."creation_date" / 1000000) < '2018-06-07'
), votes_per_answer AS (    -- up-votes and accepted-answer votes for every post
    SELECT  v."post_id",
            SUM(IFF(v."vote_type_id" = 2 , 1 , 0)) AS upvotes ,
            SUM(IFF(v."vote_type_id" = 1 , 1 , 0)) AS accepted
    FROM    STACKOVERFLOW.STACKOVERFLOW."VOTES" v
    GROUP BY v."post_id"
), answer_scores AS (       -- compute score for every selected answer
    SELECT  ans.answer_id ,
            ans.question_id ,
            COALESCE(v.upvotes , 0)   AS upvotes ,
            COALESCE(v.accepted, 0)   AS accepted ,
            10*COALESCE(v.upvotes ,0) + 15*COALESCE(v.accepted ,0) AS score
    FROM    answers ans
    LEFT JOIN votes_per_answer v  ON v."post_id" = ans.answer_id
), exploded_tags AS (       -- explode question tags for every answer
    SELECT  s.answer_id ,
            s.score ,
            tag.value::string AS tag
    FROM    answer_scores s
    JOIN    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
           ON q."id" = s.question_id
    ,       LATERAL FLATTEN(input => SPLIT(q."tags", '|')) tag
)
SELECT      tag ,
            SUM(score) AS total_score
FROM        exploded_tags
GROUP BY    tag
ORDER BY    total_score DESC NULLS LAST
LIMIT 10;