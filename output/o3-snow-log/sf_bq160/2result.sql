WITH general_forum AS (   -- id of the parent forum titled "General"
    SELECT "Id" AS "GeneralId"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "Title" = 'General'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "Id") = 1
),
sub_forums AS (          -- forums that are direct children of "General"
    SELECT f."Id" AS "ForumId"
    FROM META_KAGGLE.META_KAGGLE."FORUMS" f
    JOIN general_forum g
      ON f."ParentForumId" = g."GeneralId"
),
topics AS (              -- all topics that belong to the sub-forums
    SELECT ft.*
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" ft
    WHERE ft."ForumId" IN (SELECT "ForumId" FROM sub_forums)
),
reply_stats AS (         -- per-topic message & user counts
    SELECT fm."ForumTopicId"            AS "TopicId",
           COUNT(*)                     AS "ReplyCount",
           COUNT(DISTINCT fm."PostUserId") AS "DistinctUserRepliesCount"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
    GROUP BY fm."ForumTopicId"
),
upvote_stats AS (        -- per-topic total up-votes
    SELECT fm."ForumTopicId" AS "TopicId",
           COUNT(fmv."Id")   AS "TotalUpvotes"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"       fm
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
      ON fmv."ForumMessageId" = fm."Id"
    GROUP BY fm."ForumTopicId"
),
topic_metrics AS (       -- combine everything, replacing NULLs with 0
    SELECT
        t."Id",
        t."CreationDate",
        t."Title",
        COALESCE(rs."ReplyCount",0)              AS "ReplyCount",
        COALESCE(rs."DistinctUserRepliesCount",0) AS "DistinctUserRepliesCount",
        COALESCE(us."TotalUpvotes",0)            AS "TotalUpvotes",
        COALESCE(t."TotalViews",0)               AS "TotalViews",
        t."ForumId"
    FROM topics t
    LEFT JOIN reply_stats  rs ON rs."TopicId" = t."Id"
    LEFT JOIN upvote_stats us ON us."TopicId" = t."Id"
)
SELECT
    tm."CreationDate",
    tm."Title",
    pf."Title"                          AS "ParentForumTitle",
    tm."ReplyCount",
    tm."DistinctUserRepliesCount",
    tm."TotalUpvotes",
    tm."TotalViews"
FROM topic_metrics tm
JOIN META_KAGGLE.META_KAGGLE."FORUMS" sf ON sf."Id" = tm."ForumId"
JOIN META_KAGGLE.META_KAGGLE."FORUMS" pf ON pf."Id" = sf."ParentForumId"
WHERE pf."Title" = 'General'
ORDER BY tm."CreationDate" ASC NULLS LAST
LIMIT 5;