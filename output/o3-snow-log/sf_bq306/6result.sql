WITH user_answers AS (   -- answers by the user before 7 Jun 2018
    SELECT 
        pa."id"          AS answer_id,
        pa."parent_id"   AS question_id
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" pa
    WHERE pa."owner_user_id" = 1908967
      AND pa."creation_date" < 1528329600000000           -- 2018-06-07 00:00:00 UTC (µs)
), 

vote_counts AS (         -- up-votes and “accepted” votes on those answers
    SELECT 
        v."post_id"                                   AS answer_id,
        SUM(CASE WHEN v."vote_type_id" = 2 THEN 1 END) AS up_cnt,
        SUM(CASE WHEN v."vote_type_id" = 1 THEN 1 END) AS acc_cnt
    FROM STACKOVERFLOW.STACKOVERFLOW."VOTES" v
    JOIN user_answers ua ON ua.answer_id = v."post_id"
    WHERE v."vote_type_id" IN (1,2)
    GROUP BY v."post_id"
), 

answer_scores AS (       -- score per answer
    SELECT
        ua.answer_id,
        ua.question_id,
        COALESCE(vc.up_cnt ,0) AS up_cnt ,
        COALESCE(vc.acc_cnt,0) AS acc_cnt,
        10*COALESCE(vc.up_cnt ,0) +                 -- 10 × up-votes
        15*COALESCE(vc.acc_cnt,0) AS score          -- 15 × accepted votes
    FROM user_answers ua
    LEFT JOIN vote_counts vc ON vc.answer_id = ua.answer_id
), 

answer_tags AS (         -- explode tags per answer
    SELECT 
        t.value::STRING      AS tag,
        a.score
    FROM answer_scores a
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
         ON q."id" = a.question_id
    , LATERAL FLATTEN( input => SPLIT(COALESCE(q."tags",''),'|') ) t
    WHERE t.value IS NOT NULL AND t.value <> ''
) 

SELECT 
    tag,
    SUM(score) AS total_score
FROM answer_tags
GROUP BY tag
ORDER BY total_score DESC NULLS LAST
LIMIT 10;