WITH first_messages AS (   /* every topic’s very first message */
    SELECT
        FT."FirstForumMessageId" AS "MESSAGE_ID"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" FT
    WHERE FT."FirstForumMessageId" IS NOT NULL
),

message_scores AS (        /* score of each first message = # distinct voters */
    SELECT
        FM."Id"                                 AS "MESSAGE_ID",
        FM."PostUserId"                         AS "AUTHOR_ID",
        COALESCE(COUNT(DISTINCT FMV."FromUserId"),0) AS "MESSAGE_SCORE"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"        FM
    JOIN first_messages                                  FID
         ON FM."Id" = FID."MESSAGE_ID"
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" FMV
           ON FMV."ForumMessageId" = FM."Id"
    GROUP BY FM."Id", FM."PostUserId"
),

author_scores AS (         /* best-scoring first message for each author */
    SELECT
        "AUTHOR_ID",
        MAX("MESSAGE_SCORE") AS "AUTHOR_SCORE"
    FROM message_scores
    GROUP BY "AUTHOR_ID"
),

avg_score AS (             /* average score of all first messages */
    SELECT
        AVG("MESSAGE_SCORE") AS "AVG_MESSAGE_SCORE"
    FROM message_scores
),

top_authors AS (           /* top three users by their message score */
    SELECT *
    FROM author_scores
    ORDER BY "AUTHOR_SCORE" DESC NULLS LAST
    LIMIT 3
)

SELECT
    U."UserName",
    ROUND(ABS(TA."AUTHOR_SCORE" - A."AVG_MESSAGE_SCORE"), 4) AS "SCORE_DIFFERENCE"
FROM top_authors TA
JOIN META_KAGGLE.META_KAGGLE."USERS" U
      ON U."Id" = TA."AUTHOR_ID"
CROSS JOIN avg_score A
ORDER BY TA."AUTHOR_SCORE" DESC NULLS LAST;