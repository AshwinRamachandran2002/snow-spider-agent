WITH "GENERAL_FORUMS" AS (          -- all top‑level forums titled “General”
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "Title" = 'General'
),
"SUB_FORUMS" AS (                   -- every forum whose parent is any “General” forum
    SELECT "Id",
           "Title"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "ParentForumId" IN (SELECT "Id" FROM "GENERAL_FORUMS")
),
"TOPICS" AS (                       -- topics that belong to those sub‑forums
    SELECT  t."Id",
            t."CreationDate",
            t."Title",
            sf."Title"                       AS "ParentForumTitle",
            COALESCE(t."TotalViews", 0)      AS "TotalViews"
    FROM    META_KAGGLE.META_KAGGLE."FORUMTOPICS" t
    JOIN    "SUB_FORUMS" sf
          ON sf."Id" = t."ForumId"
),
"REPLIES" AS (                      -- reply & unique‑poster counts per topic
    SELECT  fm."ForumTopicId"                  AS "TopicId",
            COUNT(*)                           AS "ReplyCount",
            COUNT(DISTINCT fm."PostUserId")    AS "DistinctUserReplies"
    FROM    META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
    GROUP BY fm."ForumTopicId"
),
"VOTES" AS (                        -- total up‑votes per topic
    SELECT  fm."ForumTopicId"                  AS "TopicId",
            COUNT(v."Id")                      AS "TotalUpvotes"
    FROM    META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
    JOIN    META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
          ON v."ForumMessageId" = fm."Id"
    GROUP BY fm."ForumTopicId"
)
SELECT  TO_TIMESTAMP_LTZ(t."CreationDate" / 1000000) AS "CreationDate",
        t."Title",
        t."ParentForumTitle",
        COALESCE(r."ReplyCount", 0)                  AS "ReplyCount",
        COALESCE(r."DistinctUserReplies", 0)         AS "DistinctUserReplies",
        COALESCE(v."TotalUpvotes", 0)                AS "TotalUpvotes",
        t."TotalViews"                               AS "TotalViews"
FROM    "TOPICS" t
LEFT JOIN "REPLIES" r ON r."TopicId" = t."Id"
LEFT JOIN "VOTES"   v ON v."TopicId" = t."Id"
ORDER BY t."CreationDate" ASC
LIMIT 5;