SELECT
    TO_TIMESTAMP_LTZ(t."CreationDate" / 1e6) AS "creation_date",
    COALESCE(t."Title", '') AS "title",
    f."Title" AS "parent_forum",
    COALESCE(t."TotalReplies", 0) AS "reply_count",
    COALESCE(user_counts."distinct_user_count", 0) AS "distinct_user_count",
    COALESCE(upvote_counts."upvotes", 0) AS "upvotes",
    COALESCE(t."TotalViews", 0) AS "total_views"
FROM
    META_KAGGLE.META_KAGGLE.FORUMTOPICS t
    JOIN META_KAGGLE.META_KAGGLE.FORUMS f ON t."ForumId" = f."Id"
    LEFT JOIN (
        SELECT
            m."ForumTopicId",
            COUNT(DISTINCT m."PostUserId") AS "distinct_user_count"
        FROM
            META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
        GROUP BY
            m."ForumTopicId"
    ) user_counts ON t."Id" = user_counts."ForumTopicId"
    LEFT JOIN (
        SELECT
            m."ForumTopicId",
            COUNT(v."Id") AS "upvotes"
        FROM
            META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
            LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v ON m."Id" = v."ForumMessageId"
        GROUP BY
            m."ForumTopicId"
    ) upvote_counts ON t."Id" = upvote_counts."ForumTopicId"
WHERE
    f."Title" = 'General'
ORDER BY
    t."CreationDate" ASC
LIMIT 5;