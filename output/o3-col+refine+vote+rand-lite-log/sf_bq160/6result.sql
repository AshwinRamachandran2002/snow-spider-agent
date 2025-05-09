SELECT
    t."CreationDate",
    t."Title",
    parent."Title"                                                AS "ParentForumTitle",
    COALESCE(msg_ct."ReplyCount",            0)                   AS "ReplyCount",
    COALESCE(user_ct."DistinctUserReplies",  0)                   AS "DistinctUserReplies",
    COALESCE(up_ct."TotalUpVotes",           0)                   AS "TotalUpVotes",
    COALESCE(t."TotalViews",                 0)                   AS "TotalViews"
FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS               t
JOIN META_KAGGLE.META_KAGGLE.FORUMS                    child
     ON child."Id" = t."ForumId"
JOIN META_KAGGLE.META_KAGGLE.FORUMS                    parent
     ON parent."Id" = child."ParentForumId"
LEFT JOIN (
       SELECT "ForumTopicId",
              COUNT(*) AS "ReplyCount"
       FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES
       GROUP BY "ForumTopicId"
) msg_ct
     ON msg_ct."ForumTopicId" = t."Id"
LEFT JOIN (
       SELECT "ForumTopicId",
              COUNT(DISTINCT "PostUserId") AS "DistinctUserReplies"
       FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES
       GROUP BY "ForumTopicId"
) user_ct
     ON user_ct."ForumTopicId" = t."Id"
LEFT JOIN (
       SELECT m."ForumTopicId",
              COUNT(v."Id") AS "TotalUpVotes"
       FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES        m
       LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v
              ON v."ForumMessageId" = m."Id"
       GROUP BY m."ForumTopicId"
) up_ct
     ON up_ct."ForumTopicId" = t."Id"
WHERE parent."Title" ILIKE '%general%'
ORDER BY t."CreationDate" ASC NULLS LAST
LIMIT 5;