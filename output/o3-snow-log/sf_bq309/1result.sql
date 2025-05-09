WITH "badge_counts" AS (     -- total badges per user
    SELECT
        "user_id",
        COUNT(*) AS "badge_count"
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
"answer_max_score" AS (      -- highest-scoring answer per question
    SELECT
        "parent_id"                  AS "question_id",
        MAX("score")                 AS "max_answer_score"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
    GROUP BY "parent_id"
),
"qualifying_questions" AS (  -- questions that satisfy the requirement
    SELECT
        q.*,
        am."max_answer_score"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
    LEFT JOIN "answer_max_score" am
           ON am."question_id" = q."id"
    WHERE
          q."body" IS NOT NULL
      AND (
              q."accepted_answer_id" IS NOT NULL               -- has accepted answer
           OR (                                                -- otherwise needs high-ratio answer
                  q."accepted_answer_id" IS NULL
              AND q."view_count" > 0
              AND am."max_answer_score" IS NOT NULL
              AND (am."max_answer_score" / q."view_count") > 0.01
           )
      )
)
SELECT
    q."id"                              AS "question_id",
    LENGTH(q."body")                    AS "body_length",
    u."reputation"                      AS "reputation",
    (u."up_votes" - u."down_votes")     AS "net_votes",
    COALESCE(b."badge_count", 0)        AS "badge_count"
FROM "qualifying_questions"       q
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
      ON u."id" = q."owner_user_id"
LEFT JOIN "badge_counts" b
      ON b."user_id" = u."id"
ORDER BY "body_length" DESC NULLS LAST
LIMIT 10;