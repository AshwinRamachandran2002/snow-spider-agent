WITH user_answers AS (   -- answers written by the user before 7 Jun 2018
    SELECT  "id",
            "parent_id"
    FROM    STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    WHERE   "owner_user_id" = 1908967
      AND   "creation_date" < 1528329600000000          -- 2018-06-07 UTC
),
answer_votes AS (        -- up-votes and “accepted answer” votes for those answers
    SELECT  "post_id",
            SUM(CASE WHEN "vote_type_id" = 2 THEN 1 ELSE 0 END)  AS upvotes,
            SUM(CASE WHEN "vote_type_id" = 1 THEN 1 ELSE 0 END)  AS accepts
    FROM    STACKOVERFLOW.STACKOVERFLOW.VOTES
    WHERE   "vote_type_id" IN (1,2)
      AND   "creation_date" < 1528329600000000
      AND   "post_id" IN (SELECT "id" FROM user_answers)
    GROUP BY "post_id"
),
answers_with_scores AS ( -- combine answers with their vote counts
    SELECT  ua."id",
            COALESCE(av.upvotes ,0)  AS upvotes,
            COALESCE(av.accepts ,0)  AS accepts,
            ua."parent_id"
    FROM    user_answers ua
            LEFT JOIN answer_votes av
                   ON ua."id" = av."post_id"
),
question_tags AS (       -- explode question tags for every answer
    SELECT  aws."id"                    AS answer_id,
            aws.upvotes,
            aws.accepts,
            f.value::string             AS tag
    FROM    answers_with_scores   aws
            JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
                 ON q."id" = aws."parent_id"
            , LATERAL FLATTEN( INPUT => SPLIT(q."tags", '|') ) f
)
SELECT  tag,
        10 * SUM(upvotes) + 15 * SUM(accepts)   AS total_score
FROM    question_tags
GROUP BY tag
ORDER BY total_score DESC NULLS LAST
LIMIT 10;