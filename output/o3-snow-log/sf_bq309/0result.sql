WITH "QUESTIONS" AS (   -- all questions with body length
    SELECT
        q."id"                       AS "question_id",
        q."owner_user_id"            AS "user_id",
        q."view_count",
        q."accepted_answer_id",
        LENGTH(q."body")             AS "body_length"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
),
"ANSWER_STATS" AS (     -- best-scoring answer per question
    SELECT
        a."parent_id"                AS "question_id",
        MAX(a."score")               AS "best_answer_score"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
    GROUP BY a."parent_id"
),
"GOOD_QUESTIONS" AS (   -- questions that satisfy the rules
    SELECT q.*
    FROM "QUESTIONS"      q
    LEFT JOIN "ANSWER_STATS" s
           ON s."question_id" = q."question_id"
    WHERE q."accepted_answer_id" IS NOT NULL
       OR (
            q."accepted_answer_id" IS NULL
            AND q."view_count" > 0
            AND s."best_answer_score" IS NOT NULL
            AND (s."best_answer_score" / q."view_count") > 0.01
          )
),
"USER_BADGES" AS (      -- badge counts per user
    SELECT
        b."user_id",
        COUNT(*) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES b
    GROUP BY b."user_id"
)

SELECT
    gq."question_id",
    gq."body_length",
    u."reputation"                                            AS "user_reputation",
    COALESCE(u."up_votes",0) - COALESCE(u."down_votes",0)     AS "user_net_votes",
    COALESCE(ub."badge_count",0)                              AS "badge_count"
FROM "GOOD_QUESTIONS" gq
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.USERS  u  ON u."id"       = gq."user_id"
LEFT JOIN "USER_BADGES"                        ub ON ub."user_id" = gq."user_id"
ORDER BY gq."body_length" DESC NULLS LAST
LIMIT 10;