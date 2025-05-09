WITH questions AS (
    SELECT
        "id",
        "tags",
        "score",
        "answer_count",
        "owner_user_id",
        "view_count",
        "comment_count",
        "accepted_answer_id",
        "creation_date"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"
    WHERE "creation_date" >= 1451606400000000          -- 2016-01-01
      AND "creation_date" <  1454284800000000          -- 2016-02-01
      AND LOWER("tags") LIKE '%javascript%'
      AND (
             LOWER("tags") LIKE '%xss%'         OR
             LOWER("tags") LIKE '%cross-site%'  OR
             LOWER("tags") LIKE '%exploit%'     OR
             LOWER("tags") LIKE '%cybersecurity%'
          )
),
answers AS (
    SELECT
        "id",
        "owner_user_id",
        "score",
        "comment_count",
        "creation_date"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS"
    WHERE "creation_date" >= 1451606400000000          -- 2016-01-01
      AND "creation_date" <  1454284800000000          -- 2016-02-01
)
SELECT
    a."id"                AS "ANSWER_ID",
    ans_u."reputation"    AS "ANSWERER_REPUTATION",
    a."score"             AS "ANSWER_SCORE",
    a."comment_count"     AS "ANSWER_COMMENT_COUNT",
    q."tags"              AS "QUESTION_TAGS",
    q."score"             AS "QUESTION_SCORE",
    q."answer_count"      AS "QUESTION_ANSWER_COUNT",
    ask_u."reputation"    AS "ASKER_REPUTATION",
    q."view_count"        AS "QUESTION_VIEW_COUNT",
    q."comment_count"     AS "QUESTION_COMMENT_COUNT"
FROM questions q
JOIN answers a
      ON a."id" = q."accepted_answer_id"
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" ans_u
      ON ans_u."id" = a."owner_user_id"
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" ask_u
      ON ask_u."id" = q."owner_user_id";