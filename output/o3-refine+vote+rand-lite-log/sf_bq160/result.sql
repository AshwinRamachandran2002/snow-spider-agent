WITH general_forum AS (
    SELECT "Id" AS general_id
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "Title" = 'General'
),
sub_forums AS (
    SELECT "Id" AS subforum_id
    FROM META_KAGGLE.META_KAGGLE.FORUMS f
    JOIN general_forum g
      ON f."ParentForumId" = g.general_id
),
topic_base AS (
    SELECT
        ft."Id"            AS topic_id,
        ft."CreationDate"  AS raw_creation,
        ft."Title",
        COALESCE(ft."TotalViews",0) AS total_views
    FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS ft
    JOIN sub_forums sf
      ON ft."ForumId" = sf.subforum_id
)
SELECT
    TO_TIMESTAMP(raw_creation/1000000)                 AS "CreationDate",
    "Title",
    'General'                                          AS "ParentForumTitle",
    COALESCE(COUNT(DISTINCT fm."Id"),0)                AS "ReplyCount",
    COALESCE(COUNT(DISTINCT fm."PostUserId"),0)        AS "DistinctUserRepliesCount",
    COALESCE(COUNT(fmv."Id"),0)                        AS "TotalUpvotes",
    total_views                                        AS "TotalViews"
FROM topic_base tb
LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGES fm
       ON fm."ForumTopicId" = tb.topic_id
LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES fmv
       ON fmv."ForumMessageId" = fm."Id"
GROUP BY
    tb.topic_id,
    raw_creation,
    "Title",
    total_views
ORDER BY
    raw_creation ASC
LIMIT 5;