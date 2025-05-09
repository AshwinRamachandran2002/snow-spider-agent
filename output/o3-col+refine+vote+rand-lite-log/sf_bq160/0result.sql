WITH parent_forums AS (          -- forums whose title contains “General”
    SELECT "Id",
           "Title"
    FROM   META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE  "Title" ILIKE '%General%'
),
sub_forums AS (                  -- direct children of the parent forums above
    SELECT "Id",
           "ParentForumId"
    FROM   META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE  "ParentForumId" IN ( SELECT "Id" FROM parent_forums )
),
topic_base AS (                  -- all topics that live inside those sub-forums
    SELECT "Id",
           "ForumId",
           "CreationDate",
           "Title",
           "TotalViews"
    FROM   META_KAGGLE.META_KAGGLE."FORUMTOPICS"
    WHERE  "ForumId" IN ( SELECT "Id" FROM sub_forums )
),
reply_stats AS (                 -- replies and distinct users per topic
    SELECT  m."ForumTopicId"            AS "TopicId",
            COUNT(*)                    AS "ReplyCount",
            COUNT(DISTINCT m."PostUserId") AS "DistinctUserReplies"
    FROM    META_KAGGLE.META_KAGGLE."FORUMMESSAGES" m
    GROUP BY m."ForumTopicId"
),
vote_stats AS (                  -- up-votes per topic
    SELECT  m."ForumTopicId"     AS "TopicId",
            COUNT(v."Id")        AS "TotalUpvotes"
    FROM    META_KAGGLE.META_KAGGLE."FORUMMESSAGES"       m
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
           ON v."ForumMessageId" = m."Id"
    GROUP BY m."ForumTopicId"
)
SELECT  tb."CreationDate",
        tb."Title",
        pf."Title"                           AS "ParentForumTitle",
        COALESCE(rs."ReplyCount",0)          AS "ReplyCount",
        COALESCE(rs."DistinctUserReplies",0) AS "DistinctUserReplies",
        COALESCE(vs."TotalUpvotes",0)        AS "TotalUpvotes",
        COALESCE(tb."TotalViews",0)          AS "TotalViews"
FROM        topic_base  tb
JOIN        sub_forums  sf ON sf."Id" = tb."ForumId"
JOIN        parent_forums pf ON pf."Id" = sf."ParentForumId"
LEFT JOIN   reply_stats rs ON rs."TopicId" = tb."Id"
LEFT JOIN   vote_stats  vs ON vs."TopicId" = tb."Id"
ORDER BY    tb."CreationDate" ASC
LIMIT 5;