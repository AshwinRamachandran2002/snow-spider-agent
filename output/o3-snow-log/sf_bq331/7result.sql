WITH first_messages AS (   -- one first message per forum topic
    SELECT  fm."Id"                         AS message_id,
            fm."PostUserId"                 AS user_id
    FROM    (
                SELECT  fm.*,
                        ROW_NUMBER() OVER (
                            PARTITION BY fm."ForumTopicId"
                            ORDER BY TO_TIMESTAMP(fm."PostDate",'MM/DD/YYYY HH24:MI:SS') ,
                                     fm."Id"
                        )                   AS rn
                FROM    META_KAGGLE.META_KAGGLE.FORUMMESSAGES fm
                WHERE   fm."ForumTopicId" IS NOT NULL
            ) fm
    WHERE   rn = 1
),
message_scores AS (        -- score for every first message
    SELECT  fm.message_id,
            fm.user_id,
            COUNT ( DISTINCT fmv."FromUserId") AS message_score
    FROM    first_messages fm
            LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES fmv
                   ON fm.message_id = fmv."ForumMessageId"
    GROUP BY fm.message_id, fm.user_id
),
avg_score AS (              -- average score of all first messages
    SELECT AVG(message_score) AS avg_message_score
    FROM   message_scores
),
user_scores AS (            -- aggregate message scores per author
    SELECT  ms.user_id,
            SUM(ms.message_score) AS user_message_score
    FROM    message_scores ms
    GROUP BY ms.user_id
),
ranked_users AS (           -- add absolute difference from the average
    SELECT  us.user_id,
            us.user_message_score,
            ABS(us.user_message_score - a.avg_message_score) AS score_diff
    FROM    user_scores us
            CROSS JOIN avg_score a
)
SELECT  u."UserName",
        ranked_users.score_diff
FROM    ranked_users
        JOIN META_KAGGLE.META_KAGGLE.USERS u
          ON ranked_users.user_id = u."Id"
ORDER BY ranked_users.user_message_score DESC NULLS LAST
FETCH 3 ROWS ONLY;