WITH ParentForumId AS (
  SELECT "Id" 
  FROM META_KAGGLE.META_KAGGLE.FORUMS 
  WHERE "Title" ILIKE 'general'
),
SubForums AS (
  SELECT f."Id" AS "ForumId"
  FROM META_KAGGLE.META_KAGGLE.FORUMS f
  WHERE f."ParentForumId" IN (SELECT "Id" FROM ParentForumId)
  OR f."Id" IN (SELECT "Id" FROM ParentForumId)
)
SELECT
  t."CreationDate",
  COALESCE(t."Title", '[No Title]') AS "Title",
  'general' AS "ParentForum",
  COALESCE(t."TotalReplies", 0) AS "ReplyCount",
  COALESCE(COUNT(DISTINCT m."PostUserId"), 0) AS "DistinctUserCount",
  COALESCE(COUNT(v."Id"), 0) AS "Upvotes",
  COALESCE(t."TotalViews", 0) AS "TotalViews"
FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS t
JOIN SubForums f ON t."ForumId" = f."ForumId"
LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES m ON t."Id" = m."ForumTopicId"
LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v ON m."Id" = v."ForumMessageId"
GROUP BY t."Id", t."CreationDate", t."Title", t."TotalReplies", t."TotalViews"
ORDER BY t."CreationDate" ASC NULLS LAST
LIMIT 5;