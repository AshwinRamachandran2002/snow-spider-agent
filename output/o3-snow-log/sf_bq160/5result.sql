WITH general_forum AS (
    SELECT "Id" AS general_id
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "Title" = 'General'
),
sub_forums AS (        -- direct children of "General"
    SELECT "Id"
    FROM META_KAGGLE.META_KAGGLE."FORUMS" f
    JOIN general_forum g
      ON f."ParentForumId" = g.general_id
),
topic_base AS (        -- all topics that live in those sub-forums
    SELECT
        t."Id"                           AS topic_id,
        TO_TIMESTAMP(t."CreationDate"/1000000) AS creation_ts,
        t."Title"                        AS topic_title,
        COALESCE(t."TotalViews",0)       AS total_views
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" t
    JOIN sub_forums sf
      ON t."ForumId" = sf."Id"
),
message_counts AS (    -- per-topic message & user counts
    SELECT
        fm."ForumTopicId"                        AS topic_id,
        COUNT(*)                                 AS reply_count,
        COUNT(DISTINCT fm."PostUserId")          AS distinct_user_replies
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
    JOIN topic_base tb
      ON fm."ForumTopicId" = tb.topic_id
    GROUP BY fm."ForumTopicId"
),
upvote_counts AS (     -- per-topic total up-votes
    SELECT
        fm."ForumTopicId"                AS topic_id,
        COUNT(fmv."Id")                  AS total_upvotes
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
      ON fm."Id" = fmv."ForumMessageId"
    GROUP BY fm."ForumTopicId"
)
SELECT
    tb.creation_ts                       AS "CreationDate",
    tb.topic_title                       AS "Title",
    'General'                            AS "ParentForumTitle",
    COALESCE(mc.reply_count,0)           AS "ReplyCount",
    COALESCE(mc.distinct_user_replies,0) AS "DistinctUserRepliesCount",
    COALESCE(uc.total_upvotes,0)         AS "TotalUpvotes",
    tb.total_views                       AS "TotalViews"
FROM topic_base tb
LEFT JOIN message_counts mc  ON tb.topic_id = mc.topic_id
LEFT JOIN upvote_counts  uc  ON tb.topic_id = uc.topic_id
ORDER BY tb.creation_ts ASC
LIMIT 5;