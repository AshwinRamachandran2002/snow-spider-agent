WITH general_forum AS (  -- id of the parent forum titled "General"
    SELECT "Id" AS "GeneralForumId"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "Title" = 'General'
    LIMIT 1
),
/* number of messages and distinct users per topic */
msg_stats AS (
    SELECT
        "ForumTopicId",
        COUNT(*)                       AS "ReplyCount",
        COUNT(DISTINCT "PostUserId")   AS "DistinctUserReplies"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"
    GROUP BY "ForumTopicId"
),
/* total up‑votes on all messages inside each topic */
vote_stats AS (
    SELECT
        m."ForumTopicId",
        COUNT(v."Id")                  AS "TotalUpVotes"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"        m
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
           ON v."ForumMessageId" = m."Id"
    GROUP BY m."ForumTopicId"
)
SELECT
    TO_TIMESTAMP_NTZ(t."CreationDate" / 1000000)  AS "CreationDate",
    t."Title"                                     AS "TopicTitle",
    f."Title"                                     AS "ParentForumTitle",
    COALESCE(ms."ReplyCount",0)                   AS "ReplyCount",
    COALESCE(ms."DistinctUserReplies",0)          AS "DistinctUserReplies",
    COALESCE(vs."TotalUpVotes",0)                 AS "TotalUpVotes",
    COALESCE(t."TotalViews",0)                    AS "TotalViews"
FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS"  t
JOIN META_KAGGLE.META_KAGGLE."FORUMS"       f
     ON t."ForumId" = f."Id"
JOIN general_forum gf
     ON f."ParentForumId" = gf."GeneralForumId"      -- ensure the topic’s forum is under “General”
LEFT JOIN msg_stats  ms ON ms."ForumTopicId" = t."Id"
LEFT JOIN vote_stats vs ON vs."ForumTopicId" = t."Id"
ORDER BY t."CreationDate" ASC
LIMIT 5;