/*  Earliest five forum-topics that live in any sub-forum whose parent forum’s
    title is “General”, together with the requested statistics.               */

WITH general_forum AS (   -- id of the “General” forum
    SELECT "Id"
    FROM   META_KAGGLE.META_KAGGLE.FORUMS
    WHERE  "Title" = 'General'
    LIMIT  1
),
sub_forums AS (           -- every forum that sits directly under “General”
    SELECT  f."Id"   AS "ForumId",
            f."Title" AS "ParentForumTitle"
    FROM    META_KAGGLE.META_KAGGLE.FORUMS f
            JOIN general_forum g ON f."ParentForumId" = g."Id"
),
topic_stats AS (          -- aggregate all statistics per topic
    SELECT
        t."Id"                                  AS "TopicId",
        t."CreationDate",
        t."Title"                               AS "TopicTitle",
        sf."ParentForumTitle",
        COALESCE( COUNT ( DISTINCT fm."Id" )                , 0 ) AS "ReplyCount",
        COALESCE( COUNT ( DISTINCT fm."PostUserId" )        , 0 ) AS "DistinctUserReplies",
        COALESCE( COUNT ( DISTINCT v."Id" )                 , 0 ) AS "TotalUpvotes",
        COALESCE( t."TotalViews"                            , 0 ) AS "TotalViews"
    FROM    META_KAGGLE.META_KAGGLE.FORUMTOPICS        t
            JOIN sub_forums                           sf ON t."ForumId" = sf."ForumId"
            LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES       fm ON fm."ForumTopicId" = t."Id"
            LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES   v  ON v."ForumMessageId" = fm."Id"
    GROUP BY
            t."Id",
            t."CreationDate",
            t."Title",
            sf."ParentForumTitle",
            t."TotalViews"
)
SELECT
    "CreationDate",
    "TopicTitle"          AS "Title",
    "ParentForumTitle",
    "ReplyCount",
    "DistinctUserReplies",
    "TotalUpvotes",
    "TotalViews"
FROM   topic_stats
ORDER  BY "CreationDate" ASC NULLS LAST
LIMIT  5;