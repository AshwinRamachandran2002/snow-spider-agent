WITH general_sub_forums AS (      -- every direct child forum of the parent forum named “General”
    SELECT f."Id"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"  f
    JOIN META_KAGGLE.META_KAGGLE."FORUMS"  g
      ON f."ParentForumId" = g."Id"
    WHERE g."Title" ILIKE '%General%'      -- parent forum title
),

replies AS (                       -- total messages per topic
    SELECT "ForumTopicId",
           COUNT(*) AS "ReplyCount"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"
    GROUP BY "ForumTopicId"
),

distinct_users AS (                -- unique users per topic
    SELECT "ForumTopicId",
           COUNT(DISTINCT "PostUserId") AS "DistinctUserReplies"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"
    GROUP BY "ForumTopicId"
),

upvotes AS (                        -- total up-votes per topic
    SELECT m."ForumTopicId",
           COUNT(v."Id") AS "TotalUpvotes"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"       m
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
           ON v."ForumMessageId" = m."Id"
    GROUP BY m."ForumTopicId"
)

SELECT
    t."CreationDate",
    t."Title",
    s."Title"                                 AS "ParentForumTitle",
    COALESCE(r."ReplyCount",0)                AS "ReplyCount",
    COALESCE(d."DistinctUserReplies",0)       AS "DistinctUserReplies",
    COALESCE(u."TotalUpvotes",0)              AS "TotalUpvotes",
    COALESCE(t."TotalViews",0)                AS "TotalViews"
FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" t
JOIN META_KAGGLE.META_KAGGLE."FORUMS"       s
  ON t."ForumId" = s."Id"
LEFT JOIN replies         r ON r."ForumTopicId" = t."Id"
LEFT JOIN distinct_users  d ON d."ForumTopicId" = t."Id"
LEFT JOIN upvotes         u ON u."ForumTopicId" = t."Id"
WHERE t."ForumId" IN (SELECT "Id" FROM general_sub_forums)
ORDER BY t."CreationDate" ASC
LIMIT 5;