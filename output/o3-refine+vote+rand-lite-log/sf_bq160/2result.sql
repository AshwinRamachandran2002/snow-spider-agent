WITH general_forum AS (      /* the top‑level forum titled “General” */
    SELECT "Id" AS general_id
    FROM META_KAGGLE.META_KAGGLE.FORUMS
    WHERE "Title" = 'General'
),
sub_forums AS (              /* any direct children of “General”     */
    SELECT f."Id" AS sub_forum_id
    FROM META_KAGGLE.META_KAGGLE.FORUMS f
    JOIN general_forum g
      ON f."ParentForumId" = g.general_id
),
/* replies and distinct repliers for every topic */
message_stats AS (
    SELECT
        m."ForumTopicId",
        COUNT(*)                                   AS reply_cnt,
        COUNT(DISTINCT COALESCE(m."PostUserId",-1)) AS distinct_user_cnt
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
    GROUP BY m."ForumTopicId"
),
/* total up‑votes for every topic */
vote_stats AS (
    SELECT
        m."ForumTopicId",
        COUNT(v."Id") AS upvote_cnt
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES        m
    LEFT JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v
           ON v."ForumMessageId" = m."Id"
    GROUP BY m."ForumTopicId"
)
/* assemble the required result */
SELECT
    TO_TIMESTAMP_LTZ(t."CreationDate"/1000000)        AS "CREATION_DATE",
    t."Title"                                         AS "TITLE",
    'General'                                         AS "PARENT_FORUM_TITLE",
    COALESCE(ms.reply_cnt        ,0)                  AS "REPLY_COUNT",
    COALESCE(ms.distinct_user_cnt,0)                  AS "DISTINCT_USER_REPLIES_COUNT",
    COALESCE(vs.upvote_cnt       ,0)                  AS "TOTAL_UPVOTES",
    COALESCE(t."TotalViews"      ,0)                  AS "TOTAL_VIEWS"
FROM META_KAGGLE.META_KAGGLE.FORUMTOPICS t
JOIN sub_forums sf
  ON t."ForumId" = sf.sub_forum_id
LEFT JOIN message_stats ms
  ON ms."ForumTopicId" = t."Id"
LEFT JOIN vote_stats    vs
  ON vs."ForumTopicId" = t."Id"
ORDER BY t."CreationDate" ASC NULLS LAST
LIMIT 5;