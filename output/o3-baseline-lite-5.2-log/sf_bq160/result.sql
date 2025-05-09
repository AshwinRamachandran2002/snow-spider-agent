WITH general_forum AS (                                                      -- 1. locate the “General” forum
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "Title" = 'General'
), sub_forums AS (                                                           -- 2. all direct children of “General”
    SELECT f."Id", f."Title"
    FROM META_KAGGLE.META_KAGGLE."FORUMS" f
    JOIN general_forum g ON f."ParentForumId" = g."Id"
), topic_base AS (                                                           -- 3. topics that live in those sub‑forums
    SELECT  t."Id"                              AS topic_id,
            t."CreationDate",
            COALESCE(t."Title",'')              AS topic_title,
            COALESCE(t."TotalViews",0)          AS total_views,
            sf."Title"                          AS parent_forum_title
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" t
    JOIN sub_forums sf ON t."ForumId" = sf."Id"
), message_stats AS (                                                        -- 4. replies & distinct users
    SELECT  m."ForumTopicId"                     AS topic_id,
            COUNT(*)                             AS reply_count,
            COUNT(DISTINCT m."PostUserId")       AS distinct_user_replies
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" m
    GROUP BY m."ForumTopicId"
), vote_stats AS (                                                           -- 5. up‑votes on all messages
    SELECT  fm."ForumTopicId"                   AS topic_id,
            COUNT(v."Id")                       AS upvote_count
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES"       fm
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"  v
         ON v."ForumMessageId" = fm."Id"
    GROUP BY fm."ForumTopicId"
)
SELECT  
        TO_TIMESTAMP_NTZ("CreationDate" / 1e6)          AS "CreationDate",
        topic_title                                      AS "Title",
        parent_forum_title                               AS "ParentForumTitle",
        COALESCE(ms.reply_count,0)                       AS "ReplyCount",
        COALESCE(ms.distinct_user_replies,0)             AS "DistinctUserRepliesCount",
        COALESCE(vs.upvote_count,0)                      AS "TotalUpvotes",
        total_views                                      AS "TotalViews"
FROM topic_base tb
LEFT JOIN message_stats ms ON ms.topic_id = tb.topic_id
LEFT JOIN vote_stats    vs ON vs.topic_id = tb.topic_id
ORDER BY tb."CreationDate" ASC, tb.topic_id ASC          -- earliest first
LIMIT 5;