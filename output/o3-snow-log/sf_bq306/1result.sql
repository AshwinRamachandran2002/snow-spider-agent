WITH user_answers AS (      -- answers by the user before 7 Jun 2018
    SELECT
        "id"          AS answer_id,
        "parent_id"   AS question_id
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    WHERE "owner_user_id" = 1908967
      AND "creation_date" < 1528329600000000           -- 2018-06-07 00:00:00 UTC
), votes_per_answer AS (    -- up-votes and “accepted” votes on those answers
    SELECT
        "post_id"                                 AS answer_id,
        SUM(CASE WHEN "vote_type_id" = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN "vote_type_id" = 1 THEN 1 ELSE 0 END) AS accepted_cnt
    FROM STACKOVERFLOW.STACKOVERFLOW.VOTES
    WHERE "post_id" IN (SELECT answer_id FROM user_answers)
    GROUP BY "post_id"
), answer_scores AS (       -- score for each answer
    SELECT
        ua.answer_id,
        ua.question_id,
        COALESCE(10 * v.upvotes, 0) + COALESCE(15 * v.accepted_cnt, 0) AS score
    FROM user_answers ua
    LEFT JOIN votes_per_answer v ON ua.answer_id = v.answer_id
), answer_tags AS (         -- attach question tags to each answer
    SELECT
        a.score,
        q."tags"
    FROM answer_scores a
    JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
          ON q."id" = a.question_id
    WHERE q."tags" IS NOT NULL
), tag_scores AS (          -- total score per individual tag
    SELECT
        f.value::string                        AS tag,
        SUM(at.score)                          AS total_score
    FROM answer_tags at,
         LATERAL FLATTEN ( INPUT => SPLIT(at."tags", '|') ) f
    GROUP BY tag
)
SELECT
    tag,
    total_score
FROM tag_scores
ORDER BY total_score DESC NULLS LAST
LIMIT 10;