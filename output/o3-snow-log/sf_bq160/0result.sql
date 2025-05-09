WITH message_stats AS (
    SELECT
        m."ForumTopicId",
        COUNT(*)                                            AS "ReplyCount",
        COUNT(DISTINCT m."PostUserId")                     AS "DistinctUserReplies",
        COALESCE(SUM(CASE WHEN v."Id" IS NOT NULL THEN 1 END),0)  AS "TotalUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES            m
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES   v
           ON v."ForumMessageId" = m."Id"
    GROUP BY m."ForumTopicId"
)

SELECT
    TO_TIMESTAMP_LTZ(t."CreationDate"/1000000)            AS "CreationDate",
    t."Title"                                             AS "TopicTitle",
    fp."Title"                                            AS "ParentForumTitle",
    COALESCE(ms."ReplyCount",0)                           AS "ReplyCount",
    COALESCE(ms."DistinctUserReplies",0)                  AS "DistinctUserRepliesCount",
    COALESCE(ms."TotalUpvotes",0)                         AS "TotalUpvotes",
    COALESCE(t."TotalViews",0)                            AS "TotalViews"
FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS  t
JOIN META_KAGGLE.META_KAGGLE.FORUMS       fs  ON t."ForumId"       = fs."Id"
JOIN META_KAGGLE.META_KAGGLE.FORUMS       fp  ON fs."ParentForumId" = fp."Id"
LEFT JOIN message_stats                   ms  ON ms."ForumTopicId" = t."Id"
WHERE fp."Title" = 'General'
ORDER BY t."CreationDate" ASC NULLS LAST
LIMIT 5;