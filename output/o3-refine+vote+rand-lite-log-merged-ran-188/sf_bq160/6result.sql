WITH general AS (
    SELECT "Id" AS general_id
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "Title" = 'General'
),
sub_forums AS (
    SELECT "Id" AS forum_id
    FROM META_KAGGLE.META_KAGGLE.FORUMS f
    JOIN general g
      ON f."ParentForumId" = g.general_id
),
topic_base AS (
    SELECT  t."Id"                    AS topic_id,
            t."CreationDate"          AS creation_us,
            t."Title"                 AS topic_title,
            COALESCE(t."TotalViews",0) AS total_views
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS t
    WHERE t."ForumId" IN (SELECT forum_id FROM sub_forums)
),
msg_stats AS (
    SELECT  m."ForumTopicId"                AS topic_id,
            COUNT(*)                        AS reply_count,
            COUNT(DISTINCT m."PostUserId")  AS distinct_user_replies
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
    GROUP BY m."ForumTopicId"
),
vote_stats AS (
    SELECT  m."ForumTopicId"  AS topic_id,
            COUNT(v."Id")     AS total_upvotes
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
    JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v
      ON v."ForumMessageId" = m."Id"
    GROUP BY m."ForumTopicId"
)
SELECT  
    TO_TIMESTAMP(creation_us/1000000)               AS "CreationDate",
    topic_title                                     AS "Title",
    'General'                                       AS "ParentForumTitle",
    COALESCE(reply_count,0)                         AS "ReplyCount",
    COALESCE(distinct_user_replies,0)               AS "DistinctUserRepliesCount",
    COALESCE(total_upvotes,0)                       AS "TotalUpvotes",
    total_views                                     AS "TotalViews"
FROM topic_base
LEFT JOIN msg_stats  USING (topic_id)
LEFT JOIN vote_stats USING (topic_id)
ORDER BY creation_us ASC
LIMIT 5;