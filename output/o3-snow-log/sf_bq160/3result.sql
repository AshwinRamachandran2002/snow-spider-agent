WITH RECURSIVE sub_forums AS (   -- all forums that are children (at any depth) of “General”
    SELECT f."Id"
    FROM META_KAGGLE.META_KAGGLE."FORUMS" f
    WHERE f."Title" = 'General'
    
    UNION ALL
    
    SELECT c."Id"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"        c
    JOIN sub_forums                             p  ON c."ParentForumId" = p."Id"
),

target_topics AS (                 -- topics that live in any of those sub-forums
    SELECT t."Id"          AS topic_id,
           t."Title",
           t."CreationDate",
           COALESCE(t."TotalViews",0) AS "TotalViews"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" t
    WHERE t."ForumId" IN (SELECT "Id" FROM sub_forums)
),

message_stats AS (                 -- reply count & distinct repliers per topic
    SELECT m."ForumTopicId"              AS topic_id,
           COUNT(*)                      AS reply_count,
           COUNT(DISTINCT m."PostUserId") AS distinct_user_replies
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" m
    GROUP BY m."ForumTopicId"
),

vote_stats AS (                    -- total up-votes on messages in each topic
    SELECT m."ForumTopicId" AS topic_id,
           COUNT(v."Id")     AS total_upvotes
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"       m
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
           ON v."ForumMessageId" = m."Id"
    GROUP BY m."ForumTopicId"
)

SELECT 
    TO_TIMESTAMP_NTZ(tt."CreationDate"/1e6)          AS "CreationDate",
    tt."Title"                                       AS "Title",
    'General'                                        AS "ParentForumTitle",
    COALESCE(ms.reply_count,0)                       AS "ReplyCount",
    COALESCE(ms.distinct_user_replies,0)             AS "DistinctUserRepliesCount",
    COALESCE(vs.total_upvotes,0)                     AS "TotalUpvotes",
    tt."TotalViews"                                  AS "TotalViews"
FROM      target_topics  tt
LEFT JOIN message_stats  ms ON ms.topic_id = tt.topic_id
LEFT JOIN vote_stats     vs ON vs.topic_id = tt.topic_id
ORDER BY  tt."CreationDate" ASC
LIMIT 5;