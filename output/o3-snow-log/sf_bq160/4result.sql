WITH general_forum AS (     -- top-level “General” forum id
    SELECT "Id" AS general_id
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "Title" = 'General'
),
sub_forums AS (             -- direct children of “General”
    SELECT f."Id",
           f."Title"
    FROM META_KAGGLE.META_KAGGLE.FORUMS f
    JOIN general_forum g
      ON f."ParentForumId" = g.general_id
),
topic_base AS (             -- topics in those sub-forums
    SELECT t."Id"           AS topic_id,
           t."CreationDate" AS CreationDate,
           t."Title"        AS Title,
           t."TotalViews"   AS TotalViews,
           sf."Title"       AS ParentForumTitle
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS t
    JOIN sub_forums sf
      ON t."ForumId" = sf."Id"
),
message_stats AS (          -- replies & unique users per topic
    SELECT m."ForumTopicId"               AS topic_id,
           COUNT(*)                       AS ReplyCount,
           COUNT(DISTINCT m."PostUserId") AS DistinctUserReplies
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
    GROUP BY m."ForumTopicId"
),
vote_stats AS (             -- up-votes per topic
    SELECT fm."ForumTopicId" AS topic_id,
           COUNT(v."Id")     AS TotalUpvotes
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES fm
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v
           ON v."ForumMessageId" = fm."Id"
    GROUP BY fm."ForumTopicId"
)
SELECT
    TO_TIMESTAMP(CreationDate / 1000000)        AS "CreationDate",
    COALESCE(Title, '')                         AS "Title",
    ParentForumTitle                            AS "ParentForumTitle",
    COALESCE(ms.ReplyCount, 0)                  AS "ReplyCount",
    COALESCE(ms.DistinctUserReplies, 0)         AS "DistinctUserReplies",
    COALESCE(vs.TotalUpvotes, 0)                AS "TotalUpvotes",
    COALESCE(tb.TotalViews, 0)                  AS "TotalViews"
FROM topic_base tb
LEFT JOIN message_stats ms ON tb.topic_id = ms.topic_id
LEFT JOIN vote_stats    vs ON tb.topic_id = vs.topic_id
ORDER BY tb.CreationDate ASC
LIMIT 5;