WITH RECURSIVE
/* id of the parent forum “General” */
"GENERAL_FORUM" AS (
    SELECT "Id" AS "GeneralId"
    FROM   META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE  "Title" = 'General'
),

/* recursive list of all descendant forums of “General”             */
"SUB_FORUMS" AS (
    /* anchor: direct children of General */
    SELECT f."Id"
    FROM   META_KAGGLE.META_KAGGLE."FORUMS" f
           JOIN "GENERAL_FORUM" g
             ON f."ParentForumId" = g."GeneralId"
    UNION ALL
    /* recursive step: deeper descendants */
    SELECT f2."Id"
    FROM   META_KAGGLE.META_KAGGLE."FORUMS" f2
           JOIN "SUB_FORUMS" sf
             ON f2."ParentForumId" = sf."Id"
),

/* topics that belong to those sub‑forums                           */
"TARGET_TOPICS" AS (
    SELECT
        t."Id"                       AS topic_id,
        t."CreationDate",
        t."Title",
        COALESCE(t."TotalViews",0)   AS total_views
    FROM   META_KAGGLE.META_KAGGLE."FORUMTOPICS" t
           JOIN "SUB_FORUMS" sf
             ON t."ForumId" = sf."Id"
),

/* earliest five such topics                                        */
"EARLIEST_TOPICS" AS (
    SELECT *
    FROM   "TARGET_TOPICS"
    ORDER  BY "CreationDate" ASC, topic_id ASC
    LIMIT  5
),

/* message‑level statistics                                         */
"MESSAGE_STATS" AS (
    SELECT
        fm."ForumTopicId"                 AS topic_id,
        COUNT(*)                          AS reply_count,
        COUNT(DISTINCT fm."PostUserId")   AS distinct_user_replies
    FROM   META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
    WHERE  fm."ForumTopicId" IN (SELECT topic_id FROM "EARLIEST_TOPICS")
    GROUP  BY fm."ForumTopicId"
),

/* vote‑level statistics                                            */
"VOTE_STATS" AS (
    SELECT
        fm."ForumTopicId"   AS topic_id,
        COUNT(fmv."Id")     AS total_upvotes
    FROM   META_KAGGLE.META_KAGGLE."FORUMMESSAGES"        fm
           JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
             ON fmv."ForumMessageId" = fm."Id"
    WHERE  fm."ForumTopicId" IN (SELECT topic_id FROM "EARLIEST_TOPICS")
    GROUP  BY fm."ForumTopicId"
)

SELECT
    et."CreationDate",
    et."Title",
    'General'                              AS "ParentForumTitle",
    COALESCE(ms.reply_count,0)             AS "ReplyCount",
    COALESCE(ms.distinct_user_replies,0)   AS "DistinctUserReplies",
    COALESCE(vs.total_upvotes,0)           AS "TotalUpvotes",
    et.total_views                         AS "TotalViews"
FROM   "EARLIEST_TOPICS" et
       LEFT JOIN "MESSAGE_STATS" ms ON ms.topic_id = et.topic_id
       LEFT JOIN "VOTE_STATS"   vs ON vs.topic_id = et.topic_id
ORDER  BY et."CreationDate" ASC, et.topic_id ASC;