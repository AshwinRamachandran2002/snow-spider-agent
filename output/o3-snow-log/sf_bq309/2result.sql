WITH badge_counts AS (          -- total number of badges each user owns
    SELECT
        "user_id",
        COUNT(*) AS "total_badges"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
answer_scores AS (              -- highest-scoring answer per question
    SELECT
        "parent_id"                     AS "question_id",
        MAX("score")                    AS "max_answer_score"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    GROUP BY "parent_id"
),
eligible_questions AS (         -- questions satisfying the required conditions
    SELECT
        q."id"                            AS "question_id",
        q."owner_user_id",
        q."body",
        LENGTH(q."body")                  AS "body_length"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
    LEFT JOIN answer_scores s
           ON s."question_id" = q."id"
    WHERE
          q."accepted_answer_id" IS NOT NULL                           -- has accepted answer
       OR (                                                            -- OR meets score/view ratio rule
              q."accepted_answer_id" IS NULL
          AND q."view_count"            > 0
          AND s."max_answer_score"      IS NOT NULL
          AND (s."max_answer_score" / q."view_count") > 0.01
       )
)

SELECT
    e."question_id",
    e."body_length",
    u."reputation",
    (u."up_votes" - u."down_votes")      AS "net_votes",
    COALESCE(b."total_badges", 0)        AS "total_badges"
FROM eligible_questions                  e
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS   u  ON u."id" = e."owner_user_id"
LEFT JOIN badge_counts                   b  ON b."user_id" = u."id"
ORDER BY e."body_length" DESC NULLS LAST
LIMIT 10;