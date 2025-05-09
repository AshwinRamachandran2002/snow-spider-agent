WITH parent_forum AS (        -- id of the top‑level forum titled “General”
    SELECT "Id" AS parent_id
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "Title" = 'General' AND "ParentForumId" IS NULL
    LIMIT 1
),
sub_forums AS (               -- direct sub‑forums under “General”
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "ParentForumId" = (SELECT parent_id FROM parent_forum)
),
topic_stats AS (              -- aggregate required metrics per topic
    SELECT
        t."CreationDate"                               AS "Creation_Date",
        t."Title"                                      AS "Topic_Title",
        f."Title"                                      AS "Parent_Forum_Title",
        COUNT(m."Id")                                  AS "Reply_Count",
        COUNT(DISTINCT m."PostUserId")                 AS "Distinct_User_Replies",
        COUNT(v."Id")                                  AS "Total_Upvotes",
        COALESCE(t."TotalViews", 0)                    AS "Total_Views"
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS          t
    JOIN META_KAGGLE.META_KAGGLE.FORUMS              f  ON f."Id" = t."ForumId"
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES  m  ON m."ForumTopicId" = t."Id"
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v ON v."ForumMessageId" = m."Id"
    WHERE t."ForumId" IN (SELECT "Id" FROM sub_forums)
    GROUP BY
        t."Id",
        t."CreationDate",
        t."Title",
        f."Title",
        t."TotalViews"
)
SELECT *
FROM topic_stats
ORDER BY "Creation_Date" ASC
LIMIT 5;