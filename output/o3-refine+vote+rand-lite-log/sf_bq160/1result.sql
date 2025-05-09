WITH parent_forum AS (                 -- all forums titled “General”
    SELECT "Id", "Title"
    FROM META_KAGGLE.META_KAGGLE."FORUMS"
    WHERE "Title" = 'General'
),

sub_forums AS (                        -- direct children of any “General” forum
    SELECT f."Id", f."ParentForumId"
    FROM META_KAGGLE.META_KAGGLE."FORUMS" f
    JOIN parent_forum pf
      ON f."ParentForumId" = pf."Id"
),

/* message‑level aggregates */
message_stats AS (
    SELECT
        fm."ForumTopicId"                       AS "TopicId",
        COUNT(*)                                AS "ReplyCount",
        COUNT(DISTINCT fm."PostUserId")         AS "DistinctUserReplies"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
    GROUP BY fm."ForumTopicId"
),

/* up‑vote aggregates */
vote_stats AS (
    SELECT
        fm."ForumTopicId"                       AS "TopicId",
        COUNT(*)                                AS "TotalUpvotes"
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" mv
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
      ON mv."ForumMessageId" = fm."Id"
    GROUP BY fm."ForumTopicId"
),

combined_stats AS (                      -- merge message and vote data
    SELECT
        COALESCE(ms."TopicId", vs."TopicId")          AS "TopicId",
        COALESCE(ms."ReplyCount", 0)                  AS "ReplyCount",
        COALESCE(ms."DistinctUserReplies", 0)         AS "DistinctUserReplies",
        COALESCE(vs."TotalUpvotes", 0)                AS "TotalUpvotes"
    FROM message_stats ms
    FULL OUTER JOIN vote_stats vs
      ON ms."TopicId" = vs."TopicId"
)

SELECT
    TO_TIMESTAMP(ft."CreationDate" / 1000000)  AS "CreationDate",
    COALESCE(ft."Title", '')                   AS "Title",
    pf."Title"                                 AS "ParentForumTitle",
    COALESCE(cs."ReplyCount", 0)               AS "ReplyCount",
    COALESCE(cs."DistinctUserReplies", 0)      AS "DistinctUserReplies",
    COALESCE(cs."TotalUpvotes", 0)             AS "TotalUpvotes",
    COALESCE(ft."TotalViews", 0)               AS "TotalViews"
FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" ft
JOIN sub_forums sf
  ON ft."ForumId" = sf."Id"
JOIN parent_forum pf                        -- supplies the “General” title
  ON sf."ParentForumId" = pf."Id"
LEFT JOIN combined_stats cs
  ON ft."Id" = cs."TopicId"
ORDER BY ft."CreationDate" ASC
LIMIT 5;