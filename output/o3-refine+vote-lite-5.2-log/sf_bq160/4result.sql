WITH GENERAL_FORUM AS (
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "Title" = 'General'
),
SUB_FORUMS AS (
    SELECT 
        "Id",
        "Title" AS "SubForumTitle"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "ParentForumId" IN (SELECT "Id" FROM GENERAL_FORUM)
),
TOPICS AS (
    SELECT  
        t."Id",
        t."CreationDate",
        t."Title",
        t."ForumId",
        COALESCE(t."TotalViews",0) AS "TotalViews"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" t
    WHERE t."ForumId" IN (SELECT "Id" FROM SUB_FORUMS)
),
MESSAGE_STATS AS (
    SELECT  
        m."ForumTopicId"                   AS topic_id,
        COUNT(*)                           AS reply_count,
        COUNT(DISTINCT m."PostUserId")     AS distinct_user_replies
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" m
    GROUP BY m."ForumTopicId"
),
VOTE_STATS AS (
    SELECT  
        m."ForumTopicId"                   AS topic_id,
        COUNT(v."Id")                      AS total_upvotes
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" m
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
           ON v."ForumMessageId" = m."Id"
    GROUP BY m."ForumTopicId"
),
COMBINED AS (
    SELECT
        TO_TIMESTAMP(t."CreationDate"/1000000)                AS "CreationDate",
        t."Title"                                             AS "Title",
        sf."SubForumTitle"                                    AS "ParentForumTitle",
        COALESCE(ms.reply_count,0)                            AS "ReplyCount",
        COALESCE(ms.distinct_user_replies,0)                  AS "DistinctUserReplies",
        COALESCE(vs.total_upvotes,0)                          AS "TotalUpvotes",
        t."TotalViews"                                        AS "TotalViews"
    FROM TOPICS t
    JOIN SUB_FORUMS sf           ON t."ForumId" = sf."Id"
    LEFT JOIN MESSAGE_STATS ms   ON t."Id" = ms.topic_id
    LEFT JOIN VOTE_STATS vs      ON t."Id" = vs.topic_id
)
SELECT *
FROM COMBINED
ORDER BY "CreationDate" ASC, "Title"
LIMIT 5;