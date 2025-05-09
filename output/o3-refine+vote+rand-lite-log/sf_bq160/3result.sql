WITH general_forum AS (          -- all forums titled “General”
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "Title" = 'General'
),
sub_forums AS (                  -- every direct sub‑forum under any “General”
    SELECT f."Id",
           f."Title"
    FROM META_KAGGLE.META_KAGGLE."FORUMS" f
    JOIN general_forum gf
      ON f."ParentForumId" = gf."Id"
),
topic_core AS (                  -- topics that belong to those sub‑forums
    SELECT  t."Id"                       AS topic_id,
            t."CreationDate"             AS raw_creation_date,
            t."Title"                    AS topic_title,
            sf."Title"                   AS parent_forum_title,
            COALESCE(t."TotalViews",0)   AS total_views
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" t
    JOIN sub_forums sf
      ON sf."Id" = t."ForumId"
),
msg_stats AS (                    -- reply count & distinct user count per topic
    SELECT  m."ForumTopicId"                               AS topic_id,
            COUNT(*)                                       AS reply_count,
            COUNT(DISTINCT COALESCE(m."PostUserId",0))     AS distinct_user_replies
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" m
    GROUP BY m."ForumTopicId"
),
vote_stats AS (                   -- total up‑votes per topic
    SELECT  fm."ForumTopicId"          AS topic_id,
            COUNT(v."Id")              AS total_upvotes
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" v
           ON v."ForumMessageId" = fm."Id"
    GROUP BY fm."ForumTopicId"
)
SELECT
    TO_TIMESTAMP(raw_creation_date/1000000)      AS "CreationDate",
    topic_title                                  AS "Title",
    parent_forum_title                           AS "ParentForumTitle",
    COALESCE(ms.reply_count,0)                   AS "ReplyCount",
    COALESCE(ms.distinct_user_replies,0)         AS "DistinctUserReplies",
    COALESCE(vs.total_upvotes,0)                 AS "TotalUpvotes",
    total_views                                  AS "TotalViews"
FROM topic_core tc
LEFT JOIN msg_stats  ms ON ms.topic_id = tc.topic_id
LEFT JOIN vote_stats vs ON vs.topic_id = tc.topic_id
ORDER BY raw_creation_date ASC
LIMIT 5;