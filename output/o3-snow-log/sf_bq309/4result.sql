WITH questions AS (      -- base question information + body length
    SELECT  q."id",
            q."body",
            q."accepted_answer_id",
            q."owner_user_id",
            q."view_count",
            LENGTH(q."body")           AS body_length
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
), answer_scores AS (    -- best-scoring answer for every question
    SELECT  a."parent_id"              AS question_id,
            MAX(a."score")             AS max_answer_score
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    GROUP BY a."parent_id"
), eligible_accepted AS (              -- questions that already have an accepted answer
    SELECT *
    FROM   questions
    WHERE  "accepted_answer_id" IS NOT NULL
), eligible_ratio AS (                 -- no accepted answer but good score/view ratio
    SELECT  q.*
    FROM    questions       q
    JOIN    answer_scores   s ON s.question_id = q."id"
    WHERE   q."accepted_answer_id" IS NULL
      AND   q."view_count" > 0
      AND   (s.max_answer_score / q."view_count") > 0.01
), eligible_questions AS (             -- combine both eligible sets
    SELECT * FROM eligible_accepted
    UNION ALL
    SELECT * FROM eligible_ratio
), user_badges AS (                    -- total badges per user
    SELECT  b."user_id",
            COUNT(*) AS badge_count
    FROM    STACKOVERFLOW.STACKOVERFLOW."BADGES" b
    GROUP BY b."user_id"
)
SELECT  eq."id"                                       AS question_id,
        eq.body_length,
        u."reputation",
        (u."up_votes" - u."down_votes")               AS net_votes,
        COALESCE(ub.badge_count, 0)                   AS badge_count
FROM    eligible_questions           eq
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW."USERS"  u
       ON u."id" = eq."owner_user_id"
LEFT JOIN user_badges                ub
       ON ub."user_id" = eq."owner_user_id"
ORDER BY eq.body_length DESC NULLS LAST
LIMIT 10;