SELECT
    t."CreationDate",
    t."Title"                                   AS "TopicTitle",
    pf."Title"                                  AS "ParentForumTitle",
    COALESCE(COUNT(m."Id"), 0)                  AS "ReplyCount",
    COALESCE(COUNT(DISTINCT m."PostUserId"), 0) AS "DistinctUserReplies",
    COALESCE(COUNT(fmv."Id"), 0)                AS "TotalUpvotes",
    COALESCE(t."TotalViews", 0)                 AS "TotalViews"
FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS t
JOIN META_KAGGLE.META_KAGGLE.FORUMS cf
     ON t."ForumId" = cf."Id"
JOIN META_KAGGLE.META_KAGGLE.FORUMS pf
     ON cf."ParentForumId" = pf."Id"
LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
     ON m."ForumTopicId" = t."Id"
LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES fmv
     ON fmv."ForumMessageId" = m."Id"
WHERE pf."Title" = 'General'
GROUP BY t."CreationDate", t."Title", pf."Title", t."TotalViews"
ORDER BY t."CreationDate" ASC
LIMIT 5;