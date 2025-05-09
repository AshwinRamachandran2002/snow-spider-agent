WITH general_forum AS (   -- id(s) of the top-level forum titled “General”
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "Title" = 'General'
),

sub_forums AS (           -- any direct child forum of “General”
    SELECT "Id",
           "Title"
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "ParentForumId" IN (SELECT "Id" FROM general_forum)
),

topics AS (               -- topics that live in those sub-forums
    SELECT t."Id",
           t."CreationDate",
           t."Title"        AS "TopicTitle",
           f."Title"        AS "ParentForumTitle",
           COALESCE(t."TotalViews",0) AS "TotalViews"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS t
    JOIN sub_forums f
      ON t."ForumId" = f."Id"
),

message_stats AS (        -- replies & distinct users per topic
    SELECT m."ForumTopicId"                     AS "TopicId",
           COUNT(*)                             AS "ReplyCount",
           COUNT(DISTINCT m."PostUserId")       AS "DistinctUserReplies"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
    GROUP BY m."ForumTopicId"
),

vote_stats AS (           -- total up-votes per topic
    SELECT fm."ForumTopicId"                    AS "TopicId",
           COUNT(v."Id")                        AS "TotalUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES       fm
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v
           ON v."ForumMessageId" = fm."Id"
    GROUP BY fm."ForumTopicId"
),

combined AS (             -- bring everything together
    SELECT t."CreationDate",
           t."TopicTitle",
           t."ParentForumTitle",
           COALESCE(ms."ReplyCount",0)           AS "ReplyCount",
           COALESCE(ms."DistinctUserReplies",0)  AS "DistinctUserReplies",
           COALESCE(vs."TotalUpvotes",0)         AS "TotalUpvotes",
           t."TotalViews"
    FROM topics t
    LEFT JOIN message_stats ms  ON ms."TopicId" = t."Id"
    LEFT JOIN vote_stats    vs  ON vs."TopicId" = t."Id"
)

SELECT
    TO_TIMESTAMP_NTZ("CreationDate"/1000000)     AS "CreationDate",
    "TopicTitle"                                 AS "Title",
    "ParentForumTitle",
    "ReplyCount",
    "DistinctUserReplies"                        AS "DistinctUserRepliesCount",
    "TotalUpvotes",
    "TotalViews"
FROM combined
ORDER BY "CreationDate" ASC
LIMIT 5;