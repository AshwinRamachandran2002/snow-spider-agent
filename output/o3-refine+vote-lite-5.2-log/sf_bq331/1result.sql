WITH first_messages AS (   -- all first messages of every forum topic
    SELECT 
        fm."Id"            AS message_id,
        fm."PostUserId"    AS user_id
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS" ft
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
          ON fm."Id" = ft."FirstForumMessageId"
    WHERE ft."FirstForumMessageId" IS NOT NULL
),

message_scores AS (       -- score = # distinct voters on that message
    SELECT
        fm.message_id,
        fm.user_id,
        COALESCE(COUNT(DISTINCT fmv."FromUserId"),0) AS message_score
    FROM first_messages  fm
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
           ON fmv."ForumMessageId" = fm.message_id
    GROUP BY fm.message_id, fm.user_id
),

average_score AS (        -- average across all first‑messages
    SELECT AVG(message_score) AS avg_message_score
    FROM   message_scores
),

ranked_messages AS (      -- attach average, compute absolute difference
    SELECT
        ms.*,
        avg_score.avg_message_score,
        ABS(ms.message_score - avg_score.avg_message_score) AS score_diff
    FROM message_scores ms
    CROSS JOIN average_score avg_score
    ORDER BY ms.message_score DESC NULLS LAST
    FETCH FIRST 3 ROWS ONLY
)

SELECT
    u."UserName"                                           AS "username",
    ranked.score_diff                                      AS "score_difference_from_average"
FROM ranked_messages ranked
JOIN META_KAGGLE.META_KAGGLE."USERS" u
     ON u."Id" = ranked.user_id
ORDER BY ranked.message_score DESC NULLS LAST, u."UserName";