WITH general_forum AS (      -- id of the “General” forum
    SELECT "Id" AS general_id
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "Title" = 'General'
),

sub_forums AS (              -- all direct sub-forums of “General”
    SELECT f."Id",
           f."Title" AS sub_forum_title
    FROM META_KAGGLE.META_KAGGLE."FORUMS" f
    JOIN general_forum g
      ON f."ParentForumId" = g.general_id
),

topics_in_sub AS (           -- topics that sit in those sub-forums
    SELECT ft."Id"           AS topic_id,
           ft."CreationDate" AS creation_date,
           ft."Title"        AS topic_title,
           ft."TotalViews"   AS total_views,
           ft."ForumId"
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" ft
    JOIN sub_forums sf
      ON ft."ForumId" = sf."Id"
),

messages_stats AS (          -- reply count & distinct user count per topic
    SELECT fm."ForumTopicId"                                AS topic_id,
           COUNT(*)                                         AS reply_cnt,
           COUNT(DISTINCT COALESCE(fm."PostUserId", -1))    AS distinct_users
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
    WHERE fm."ForumTopicId" IN (SELECT topic_id FROM topics_in_sub)
    GROUP BY fm."ForumTopicId"
),

upvotes_stats AS (           -- total up-votes per topic
    SELECT fm."ForumTopicId" AS topic_id,
           COUNT(fmv."Id")   AS upvotes
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
           ON fmv."ForumMessageId" = fm."Id"
    WHERE fm."ForumTopicId" IN (SELECT topic_id FROM topics_in_sub)
    GROUP BY fm."ForumTopicId"
)

SELECT
    t.creation_date                               AS "CREATION_DATE",
    t.topic_title                                 AS "TITLE",
    sf.sub_forum_title                            AS "PARENT_FORUM_TITLE",
    COALESCE(ms.reply_cnt,       0)               AS "REPLY_COUNT",
    COALESCE(ms.distinct_users,   0)              AS "DISTINCT_USER_REPLIES",
    COALESCE(us.upvotes,          0)              AS "TOTAL_UPVOTES",
    COALESCE(t.total_views,       0)              AS "TOTAL_VIEWS"
FROM topics_in_sub t
JOIN sub_forums      sf ON t."ForumId" = sf."Id"
LEFT JOIN messages_stats ms ON t.topic_id = ms.topic_id
LEFT JOIN upvotes_stats  us ON t.topic_id = us.topic_id
ORDER BY t.creation_date ASC NULLS LAST
LIMIT 5;