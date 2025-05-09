WITH vote_counts AS (   -- how many distinct messages user A up‑voted from user B
    SELECT
        "FromUserId"  AS giver_id,
        "ToUserId"    AS receiver_id,
        COUNT(DISTINCT "ForumMessageId") AS upvotes_given
    FROM META_KAGGLE.META_KAGGLE."FORUMMESSAGEVOTES"
    GROUP BY
        giver_id,
        receiver_id
),
paired AS (            -- bring the reverse direction to the same row
    SELECT
        vc.giver_id,
        vc.receiver_id,
        vc.upvotes_given                        AS upvotes_received,          -- A → B
        COALESCE(vr.upvotes_given, 0)           AS upvotes_returned            -- B → A
    FROM vote_counts vc
    LEFT JOIN vote_counts vr
           ON vr.giver_id   = vc.receiver_id
          AND vr.receiver_id = vc.giver_id
)
SELECT
    g."UserName" AS "GiverUserName",
    r."UserName" AS "ReceiverUserName",
    paired.upvotes_received  AS "UpvotesReceived",
    paired.upvotes_returned  AS "UpvotesReturned"
FROM paired
JOIN META_KAGGLE.META_KAGGLE."USERS" g ON g."Id" = paired.giver_id
JOIN META_KAGGLE.META_KAGGLE."USERS" r ON r."Id" = paired.receiver_id
ORDER BY
    paired.upvotes_received DESC,
    paired.upvotes_returned DESC
LIMIT 1;