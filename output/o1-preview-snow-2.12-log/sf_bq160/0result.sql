WITH earliest_topics AS (
    SELECT
        ft."Id" AS "TopicId",
        ft."CreationDate",
        ft."Title",
        f."Title" AS "ParentForum",
        ft."TotalReplies",
        ft."TotalViews"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS ft
    JOIN META_KAGGLE.META_KAGGLE.FORUMS f
        ON ft."ForumId" = f."Id"
    WHERE f."Title" = 'General'
    ORDER BY ft."CreationDate" ASC
    LIMIT 5
)
SELECT
    et."CreationDate",
    et."Title",
    et."ParentForum",
    COALESCE(et."TotalReplies", 0) AS "ReplyCount",
    COALESCE(COUNT(DISTINCT fm."PostUserId"), 0) AS "DistinctUserCount",
    COALESCE(COUNT(fmv."Id"), 0) AS "Upvotes",
    COALESCE(et."TotalViews", 0) AS "TotalViews"
FROM earliest_topics et
LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES fm
    ON fm."ForumTopicId" = et."TopicId"
LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES fmv
    ON fmv."ForumMessageId" = fm."Id"
GROUP BY
    et."CreationDate",
    et."Title",
    et."ParentForum",
    et."TotalReplies",
    et."TotalViews"
ORDER BY
    et."CreationDate" ASC;