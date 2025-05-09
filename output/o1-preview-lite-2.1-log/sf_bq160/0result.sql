SELECT
  t."CreationDate",
  t."Title",
  'general' AS "ParentForum",
  COALESCE(t."TotalReplies", 0) AS "ReplyCount",
  COALESCE(u."DistinctUserCount", 0) AS "DistinctUserCount",
  COALESCE(v."TotalUpvotes", 0) AS "Upvotes",
  COALESCE(t."TotalViews", 0) AS "TotalViews"
FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS t
LEFT JOIN (
  SELECT "ForumTopicId", COUNT(DISTINCT "PostUserId") AS "DistinctUserCount"
  FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES
  GROUP BY "ForumTopicId"
) u ON t."Id" = u."ForumTopicId"
LEFT JOIN (
  SELECT m."ForumTopicId", COUNT(v."Id") AS "TotalUpvotes"
  FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
  LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v ON m."Id" = v."ForumMessageId"
  GROUP BY m."ForumTopicId"
) v ON t."Id" = v."ForumTopicId"
WHERE t."ForumId" IN (
  SELECT "Id" FROM META_KAGGLE.META_KAGGLE.FORUMS WHERE "Title" = 'General'
)
ORDER BY t."CreationDate" ASC
LIMIT 5;