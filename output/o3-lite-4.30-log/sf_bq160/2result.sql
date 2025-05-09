WITH parent_forum AS (                       -- forum titled "General"
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "Title" = 'General'
    LIMIT 1
), subforums AS (                            -- children of "General"
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "ParentForumId" IN (SELECT "Id" FROM parent_forum)
), earliest_topics AS (                      -- earliest 5 topics in those sub‑forums
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS
    WHERE "ForumId" IN (SELECT "Id" FROM subforums)
    ORDER BY "CreationDate" ASC
    LIMIT 5
)
SELECT
    t."CreationDate",
    t."Title"                                            AS "TopicTitle",
    pf."Title"                                           AS "ParentForumTitle",
    COALESCE(COUNT(m."Id"), 0)                           AS "ReplyCount",
    COALESCE(COUNT(DISTINCT m."PostUserId"), 0)          AS "DistinctUserReplies",
    COALESCE(COUNT(v."Id"), 0)                           AS "TotalUpVotes",
    COALESCE(t."TotalViews", 0)                          AS "TotalViews"
FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS             t
JOIN META_KAGGLE.META_KAGGLE.FORUMS                 sf ON sf."Id" = t."ForumId"
JOIN META_KAGGLE.META_KAGGLE.FORUMS                 pf ON pf."Id" = sf."ParentForumId"
LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES     m  ON m."ForumTopicId"   = t."Id"
LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v  ON v."ForumMessageId" = m."Id"
WHERE t."Id" IN (SELECT "Id" FROM earliest_topics)
GROUP BY
    t."Id",
    t."CreationDate",
    t."Title",
    pf."Title",
    t."TotalViews"
ORDER BY t."CreationDate" ASC;