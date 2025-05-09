WITH first_messages AS (   -- all first-messages that start a forum topic
    SELECT  "FirstForumMessageId" AS "msg_id"
    FROM    "META_KAGGLE"."META_KAGGLE"."FORUMTOPICS"
    WHERE   "FirstForumMessageId" IS NOT NULL
),
/* message-score (distinct voters) for every first-message                */
message_scores AS (
    SELECT  fm."msg_id",
            COUNT(DISTINCT fmv."FromUserId") AS "message_score"
    FROM    first_messages  fm
    LEFT JOIN "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES" fmv
           ON fmv."ForumMessageId" = fm."msg_id"
    GROUP BY fm."msg_id"
),
/* average message-score across ALL first-messages                        */
avg_score AS (
    SELECT AVG("message_score") AS "avg_message_score"
    FROM   message_scores
),
/* message-score aggregated per author (distinct voters over ALL of the   */
/* author’s first-messages)                                               */
author_scores AS (
    SELECT  m."PostUserId"                  AS "author_id",
            u."UserName"                    AS "username",
            COUNT(DISTINCT v."FromUserId")  AS "message_score"
    FROM   "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGES" m
           JOIN first_messages  fm
                ON fm."msg_id" = m."Id"
           LEFT JOIN "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES" v
                ON v."ForumMessageId" = m."Id"
           JOIN "META_KAGGLE"."META_KAGGLE"."USERS" u
                ON u."Id" = m."PostUserId"
    GROUP  BY m."PostUserId", u."UserName"
)
/* top three users, ranked by their message-scores                        */
SELECT  
        a."username",
        ABS(a."message_score" - avg."avg_message_score") AS "abs_diff_to_avg"
FROM    author_scores a
CROSS JOIN avg_score avg
ORDER BY a."message_score" DESC NULLS LAST
LIMIT 3;