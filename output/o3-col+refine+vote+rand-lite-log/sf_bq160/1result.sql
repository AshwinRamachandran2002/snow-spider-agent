WITH general_forums AS (   -- forums whose title is “General”
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "Title" ILIKE 'General'
),
sub_forums AS (           -- one-level children of those “General” forums
    SELECT "Id", "ParentForumId"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "ParentForumId" IN (SELECT "Id" FROM general_forums)
),
early_topics AS (         -- earliest five topics inside any such sub-forum
    SELECT
        t."Id"           AS "TopicId",
        t."Title",
        t."CreationDate",
        t."ForumId"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" t
    WHERE t."ForumId" IN (SELECT "Id" FROM sub_forums)
    ORDER BY t."CreationDate"
    LIMIT 5
),
msg_stats AS (            -- reply count & distinct user count
    SELECT
        m."ForumTopicId"                     AS "TopicId",
        COUNT(*)                             AS "ReplyCount",
        COUNT(DISTINCT m."PostUserId")       AS "DistinctUserReplies"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" m
    WHERE m."ForumTopicId" IN (SELECT "TopicId" FROM early_topics)
    GROUP BY m."ForumTopicId"
),
upvote_stats AS (         -- total up-votes across all messages of each topic
    SELECT
        m."ForumTopicId"  AS "TopicId",
        COUNT(v."Id")     AS "TotalUpvotes"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"       m
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
           ON v."ForumMessageId" = m."Id"
    WHERE m."ForumTopicId" IN (SELECT "TopicId" FROM early_topics)
    GROUP BY m."ForumTopicId"
)
SELECT
    et."CreationDate",
    et."Title"                              AS "TopicTitle",
    pf."Title"                              AS "ParentForumTitle",
    COALESCE(ms."ReplyCount",0)             AS "ReplyCount",
    COALESCE(ms."DistinctUserReplies",0)    AS "DistinctUserReplies",
    COALESCE(us."TotalUpvotes",0)           AS "TotalUpvotes",
    COALESCE(ft."TotalViews",0)             AS "TotalViews"
FROM early_topics           et
JOIN META_KAGGLE.META_KAGGLE."FORUMS"  sf ON et."ForumId" = sf."Id"
JOIN META_KAGGLE.META_KAGGLE."FORUMS"  pf ON sf."ParentForumId" = pf."Id"
LEFT JOIN msg_stats         ms ON ms."TopicId" = et."TopicId"
LEFT JOIN upvote_stats      us ON us."TopicId" = et."TopicId"
LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMTOPICS" ft ON ft."Id" = et."TopicId"
ORDER BY et."CreationDate";