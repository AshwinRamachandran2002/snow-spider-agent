WITH "ANS_MAX" AS (
    SELECT
        a."parent_id"          AS "question_id",
        MAX(a."score")         AS "max_answer_score"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    GROUP BY a."parent_id"
)

SELECT
    q."id"                                       AS "question_id",
    LENGTH(q."body")                             AS "body_length",
    u."reputation"                               AS "asker_reputation",
    (u."up_votes" - u."down_votes")              AS "asker_net_votes",
    COALESCE(b."badge_count", 0)                 AS "asker_badge_total"
FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"   q
JOIN STACKOVERFLOW.STACKOVERFLOW."USERS"            u  ON u."id" = q."owner_user_id"
LEFT JOIN "ANS_MAX"                                 ar ON ar."question_id" = q."id"
LEFT JOIN (
        SELECT "user_id", COUNT(*) AS "badge_count"
        FROM STACKOVERFLOW.STACKOVERFLOW."BADGES"
        GROUP BY "user_id"
)                                                   b  ON b."user_id" = u."id"
WHERE q."body" IS NOT NULL
  AND (
        q."accepted_answer_id" IS NOT NULL
        OR (
               q."accepted_answer_id" IS NULL
           AND q."view_count" > 0
           AND ar."max_answer_score" IS NOT NULL
           AND ar."max_answer_score" / q."view_count" > 0.01
        )
      )
ORDER BY "body_length" DESC NULLS LAST
LIMIT 10;