/* Top‑three users whose FIRST forum‑topic messages attracted the most
   distinct voters, along with the absolute difference from the overall
   average first‑message score.                                              */

WITH first_messages AS (      -- every “first” message in each topic
    SELECT
        fm."Id"          AS first_message_id,
        fm."PostUserId"  AS author_user_id
    FROM META_KAGGLE.META_KAGGLE."FORUMTOPICS"  ft
    JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGES" fm
          ON fm."Id" = ft."FirstForumMessageId"
),
message_scores AS (           -- message‑score = # distinct voters
    SELECT
        fm.first_message_id,
        fm.author_user_id,
        COALESCE( COUNT(DISTINCT fmv."FromUserId"), 0 ) AS message_score
    FROM first_messages fm
    LEFT JOIN META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES" fmv
           ON fmv."ForumMessageId" = fm.first_message_id
    GROUP BY fm.first_message_id, fm.author_user_id
),
avg_score AS (                -- average message‑score across ALL first messages
    SELECT AVG(message_score) AS avg_msg_score
    FROM message_scores
)

SELECT
    u."UserName",
    ABS(ms.message_score - a.avg_msg_score) AS abs_diff_from_avg
FROM message_scores          ms
JOIN META_KAGGLE.META_KAGGLE."USERS" u
      ON u."Id" = ms.author_user_id
CROSS JOIN avg_score          a
ORDER BY
    ms.message_score DESC NULLS LAST,   -- highest scores first
    u."UserName"                        -- tie‑breaker
LIMIT 3;