WITH user_answers AS (                       -- answers by the user before 7 Jun 2018
    SELECT
        "id"        AS answer_id,
        "parent_id" AS question_id
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    WHERE "owner_user_id" = 1908967
      AND "creation_date" < 1528329600000000            -- 2018-06-07 00:00:00 UTC (µs)
),
answer_votes AS (                            -- up-votes and accepted-answer votes
    SELECT
        "post_id" AS answer_id,
        SUM(CASE WHEN "vote_type_id" = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN "vote_type_id" = 1 THEN 1 ELSE 0 END) AS accepted
    FROM STACKOVERFLOW.STACKOVERFLOW.VOTES
    WHERE "vote_type_id" IN (1, 2)
    GROUP BY "post_id"
),
answer_scores AS (                           -- weighted score per answer
    SELECT
        ua.answer_id,
        ua.question_id,
        10 * COALESCE(av.upvotes ,0)
      + 15 * COALESCE(av.accepted,0) AS score
    FROM user_answers ua
    LEFT JOIN answer_votes av
           ON ua.answer_id = av.answer_id
),
answer_tags AS (                             -- attach tags of the parent question
    SELECT
        ascore.score,
        q."tags"
    FROM answer_scores ascore
    JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
          ON ascore.question_id = q."id"
    WHERE q."tags" IS NOT NULL
),
tag_scores AS (                              -- split tag string → rows
    SELECT
        TRIM(t.value::string) AS tag,
        at.score
    FROM answer_tags at,
         LATERAL FLATTEN(INPUT => SPLIT(at."tags", '|')) t
)
SELECT
    tag,
    SUM(score) AS total_score
FROM tag_scores
GROUP BY tag
ORDER BY total_score DESC NULLS LAST
LIMIT 10;