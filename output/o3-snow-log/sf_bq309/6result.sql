WITH QUESTION_CANDIDATES AS (      -- basic info + length of body
    SELECT
        q."id"                  AS "QUESTION_ID",
        q."owner_user_id"       AS "USER_ID",
        q."title"               AS "TITLE",
        q."body",
        LENGTH(q."body")        AS "BODY_LEN",
        q."accepted_answer_id"  AS "ACCEPTED_ANSWER_ID",
        q."view_count"          AS "VIEW_COUNT"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
    WHERE q."owner_user_id" IS NOT NULL
),

ANSWER_STATS AS (                 -- best score-to-view ratio per question
    SELECT
        a."parent_id"                               AS "QUESTION_ID",
        MAX( a."score" / q."view_count" )           AS "MAX_SCORE_VIEW_RATIO"
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
    JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
         ON q."id" = a."parent_id"
    WHERE q."view_count" > 0                -- avoid div-by-zero
    GROUP BY a."parent_id"
),

FILTERED_QUESTIONS AS (           -- keep questions that satisfy the rule
    SELECT qc.*
    FROM QUESTION_CANDIDATES qc
    LEFT JOIN ANSWER_STATS s
           ON qc."QUESTION_ID" = s."QUESTION_ID"
    WHERE qc."ACCEPTED_ANSWER_ID" IS NOT NULL
       OR ( qc."ACCEPTED_ANSWER_ID" IS NULL
            AND s."MAX_SCORE_VIEW_RATIO" > 0.01 )
),

USER_BADGES AS (                  -- total badges per user
    SELECT
        b."user_id"                  AS "USER_ID",
        COUNT(*)                     AS "BADGE_COUNT"
    FROM STACKOVERFLOW.STACKOVERFLOW."BADGES" b
    GROUP BY b."user_id"
)

SELECT
    fq."QUESTION_ID",
    fq."TITLE",
    fq."BODY_LEN",
    u."reputation"                  AS "USER_REPUTATION",
    (u."up_votes" - u."down_votes") AS "USER_NET_VOTES",
    COALESCE(ub."BADGE_COUNT",0)    AS "USER_BADGE_TOTAL"
FROM FILTERED_QUESTIONS fq
JOIN STACKOVERFLOW.STACKOVERFLOW."USERS"  u  ON fq."USER_ID" = u."id"
LEFT JOIN USER_BADGES                   ub ON fq."USER_ID" = ub."USER_ID"
ORDER BY fq."BODY_LEN" DESC NULLS LAST
LIMIT 10;