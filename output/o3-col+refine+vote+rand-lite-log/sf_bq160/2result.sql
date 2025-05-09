WITH general_parent_forums AS (      -- parent forums whose title contains "General"
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "Title" ILIKE '%general%'
),

sub_forums AS (                      -- their immediate sub-forums
    SELECT "Id",
           "Title",
           "ParentForumId"
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "ParentForumId" IN (SELECT "Id" FROM general_parent_forums)
),

topic_metrics AS (                   -- compute reply counts, unique users and up-votes
    SELECT
        ft."Id"                       AS "ForumTopicId",
        ft."ForumId",
        ft."CreationDate",
        ft."Title",
        COALESCE(msgs."ReplyCount",0)            AS "ReplyCount",
        COALESCE(users."DistinctUserReplies",0)  AS "DistinctUserReplies",
        COALESCE(ups."TotalUpvotes",0)           AS "TotalUpvotes",
        COALESCE(ft."TotalViews",0)              AS "TotalViews"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS ft
    JOIN sub_forums sf
         ON ft."ForumId" = sf."Id"

    /* total number of messages per topic */
    LEFT JOIN (
        SELECT "ForumTopicId",
               COUNT(*) AS "ReplyCount"
        FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES
        GROUP BY "ForumTopicId"
    ) msgs
        ON ft."Id" = msgs."ForumTopicId"

    /* number of distinct users who replied */
    LEFT JOIN (
        SELECT "ForumTopicId",
               COUNT(DISTINCT "PostUserId") AS "DistinctUserReplies"
        FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES
        GROUP BY "ForumTopicId"
    ) users
        ON ft."Id" = users."ForumTopicId"

    /* total up-votes on all messages inside the topic */
    LEFT JOIN (
        SELECT fm."ForumTopicId",
               COUNT(fmv."Id") AS "TotalUpvotes"
        FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES fm
        LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES fmv
               ON fm."Id" = fmv."ForumMessageId"
        GROUP BY fm."ForumTopicId"
    ) ups
        ON ft."Id" = ups."ForumTopicId"
)

SELECT
    tm."CreationDate",
    tm."Title"                  AS "TopicTitle",
    sf."Title"                  AS "ParentForumTitle",
    tm."ReplyCount",
    tm."DistinctUserReplies",
    tm."TotalUpvotes",
    tm."TotalViews"
FROM topic_metrics tm
JOIN sub_forums sf
     ON tm."ForumId" = sf."Id"
ORDER BY tm."CreationDate"      -- earliest topics first
LIMIT 5;