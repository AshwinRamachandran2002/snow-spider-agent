WITH answers AS (                      -- answers by the user before 2018-06-07
    SELECT  "id"        AS answer_id ,
            "parent_id" AS question_id
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    WHERE   "owner_user_id" = 1908967
      AND   "creation_date" < 1528329600000000          -- 2018-06-07 00:00:00 UTC
),
vote_counts AS (                       -- count up-votes and accepted-answer votes
    SELECT  "post_id" AS answer_id ,
            SUM(CASE WHEN "vote_type_id" = 2 THEN 1 ELSE 0 END) AS upvotes ,
            SUM(CASE WHEN "vote_type_id" = 1 THEN 1 ELSE 0 END) AS accepted_votes
    FROM    STACKOVERFLOW.STACKOVERFLOW.VOTES
    WHERE   "vote_type_id" IN (1,2)
    GROUP BY "post_id"
)
SELECT  f.VALUE::STRING AS tag ,
        SUM( 10 * COALESCE(vc.upvotes ,0)
            +15 * COALESCE(vc.accepted_votes ,0) ) AS total_score
FROM    answers  a
LEFT JOIN vote_counts vc
       ON a.answer_id   = vc.answer_id
JOIN    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
       ON a.question_id = q."id"
     ,  LATERAL FLATTEN( INPUT => SPLIT(q."tags", '|') ) f   -- explode tags
GROUP BY f.VALUE::STRING
ORDER BY total_score DESC NULLS LAST
LIMIT 10;