WITH general_parent_forums AS (   -- forums whose title is exactly "General" (case–insensitive)
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE LOWER("Title") = 'general'
),
sub_forums AS (                  -- direct children of every "General" forum
    SELECT "Id",
           "ParentForumId"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "ParentForumId" IN (SELECT "Id" FROM general_parent_forums)
),
topic_base AS (                  -- all topics that live in those sub-forums
    SELECT  "Id"            AS "TopicId",
            "ForumId",
            "Title",
            "CreationDate",
            COALESCE("TotalViews",0) AS "TotalViews"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS"
    WHERE "ForumId" IN (SELECT "Id" FROM sub_forums)
),
message_stats AS (               -- replies and distinct users per topic
    SELECT  "ForumTopicId",
            COUNT(*)                           AS reply_cnt,
            COUNT(DISTINCT "PostUserId")       AS user_cnt
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"
    WHERE "ForumTopicId" IN (SELECT "TopicId" FROM topic_base)
    GROUP BY "ForumTopicId"
),
upvote_stats AS (                -- total up-votes per topic
    SELECT  m."ForumTopicId",
            COUNT(v."Id")                     AS upvote_cnt
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"        m
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
           ON m."Id" = v."ForumMessageId"
    WHERE m."ForumTopicId" IN (SELECT "TopicId" FROM topic_base)
    GROUP BY m."ForumTopicId"
)
SELECT  t."CreationDate",
        t."Title",
        fp."Title"                           AS "ParentForumTitle",
        COALESCE(ms.reply_cnt ,0)            AS "ReplyCount",
        COALESCE(ms.user_cnt  ,0)            AS "DistinctUserReplies",
        COALESCE(us.upvote_cnt,0)            AS "TotalUpvotes",
        t."TotalViews"
FROM        topic_base               t
LEFT JOIN   message_stats            ms  ON t."TopicId" = ms."ForumTopicId"
LEFT JOIN   upvote_stats             us  ON t."TopicId" = us."ForumTopicId"
LEFT JOIN   META_KAGGLE.META_KAGGLE."FORUMS" fs ON t."ForumId" = fs."Id"
LEFT JOIN   META_KAGGLE.META_KAGGLE."FORUMS" fp ON fs."ParentForumId" = fp."Id"
ORDER BY    t."CreationDate" ASC
LIMIT 5;