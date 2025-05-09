/* Earliest five topics that live inside any sub-forum under the parent forum titled “General”,
   together with reply, user and up-vote statistics                                       */
WITH parent_forum AS (   -- the forum whose own title is exactly “General”
    SELECT "Id", "Title"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE LOWER("Title") = 'general'
),
sub_forums AS (          -- direct children of the “General” forum
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "ParentForumId" IN (SELECT "Id" FROM parent_forum)
),
earliest_topics AS (     -- pick the five earliest topics living in those sub-forums
    SELECT
        "Id",
        "ForumId",
        "CreationDate",
        "Title",
        COALESCE("TotalViews",0) AS "TotalViews"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS"
    WHERE "ForumId" IN (SELECT "Id" FROM sub_forums)
    ORDER BY "CreationDate"
    LIMIT 5
),
message_stats AS (       -- replies + unique repliers per topic
    SELECT
        "ForumTopicId"                       AS "TopicId",
        COUNT(*)                             AS "ReplyCount",
        COUNT(DISTINCT "PostUserId")         AS "DistinctUserReplies"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"
    WHERE "ForumTopicId" IN (SELECT "Id" FROM earliest_topics)
    GROUP BY "ForumTopicId"
),
vote_stats AS (          -- total up-votes across all messages of each topic
    SELECT
        fm."ForumTopicId"  AS "TopicId",
        COUNT(fv."Id")     AS "TotalUpvotes"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"        fm
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fv
           ON fv."ForumMessageId" = fm."Id"
    WHERE fm."ForumTopicId" IN (SELECT "Id" FROM earliest_topics)
    GROUP BY fm."ForumTopicId"
)
SELECT
    et."CreationDate",
    et."Title"                              AS "TopicTitle",
    pf."Title"                              AS "ParentForumTitle",
    COALESCE(ms."ReplyCount",0)             AS "ReplyCount",
    COALESCE(ms."DistinctUserReplies",0)    AS "DistinctUserReplies",
    COALESCE(vs."TotalUpvotes",0)           AS "TotalUpvotes",
    et."TotalViews"
FROM earliest_topics et
JOIN META_KAGGLE.META_KAGGLE."FORUMS" sf       ON sf."Id"  = et."ForumId"
JOIN parent_forum                  pf          ON pf."Id"  = sf."ParentForumId"
LEFT JOIN message_stats            ms          ON ms."TopicId" = et."Id"
LEFT JOIN vote_stats               vs          ON vs."TopicId" = et."Id"
ORDER BY et."CreationDate";