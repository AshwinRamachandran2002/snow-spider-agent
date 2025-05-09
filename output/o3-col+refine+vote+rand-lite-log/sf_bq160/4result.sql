WITH parent_forum AS (
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "Title" ILIKE '%general%'      -- root “General” forum
      AND "ParentForumId" IS NULL
    LIMIT 1
),
sub_forums AS (                         -- all direct children of “General”
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "ParentForumId" IN (SELECT "Id" FROM parent_forum)
),
topic_base AS (                         -- topics that live in any sub-forum
    SELECT
        t."Id"                    AS "TopicId",
        t."CreationDate",
        t."Title",
        pf."Title"                AS "ParentForumTitle",
        COALESCE(t."TotalViews",0) AS "TotalViews"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS t
    JOIN META_KAGGLE.META_KAGGLE.FORUMS sf  ON t."ForumId" = sf."Id"
    JOIN META_KAGGLE.META_KAGGLE.FORUMS pf  ON sf."ParentForumId" = pf."Id"
    WHERE sf."Id" IN (SELECT "Id" FROM sub_forums)
),
reply_cnt AS (                          -- total replies per topic
    SELECT "ForumTopicId" AS "TopicId",
           COUNT(*)        AS "ReplyCount"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES
    GROUP BY "ForumTopicId"
),
user_cnt AS (                           -- unique users per topic
    SELECT "ForumTopicId"        AS "TopicId",
           COUNT(DISTINCT "PostUserId") AS "DistinctUsers"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES
    GROUP BY "ForumTopicId"
),
upvote_cnt AS (                         -- total up-votes per topic
    SELECT m."ForumTopicId" AS "TopicId",
           COUNT(v."Id")      AS "TotalUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES       m
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v
           ON v."ForumMessageId" = m."Id"
    GROUP BY m."ForumTopicId"
)
SELECT
    b."CreationDate",
    b."Title",
    b."ParentForumTitle",
    COALESCE(r."ReplyCount",0)        AS "ReplyCount",
    COALESCE(u."DistinctUsers",0)     AS "DistinctUserReplies",
    COALESCE(up."TotalUpvotes",0)     AS "TotalUpvotes",
    b."TotalViews"
FROM topic_base b
LEFT JOIN reply_cnt  r  ON b."TopicId" = r."TopicId"
LEFT JOIN user_cnt   u  ON b."TopicId" = u."TopicId"
LEFT JOIN upvote_cnt up ON b."TopicId" = up."TopicId"
ORDER BY b."CreationDate" ASC
LIMIT 5;