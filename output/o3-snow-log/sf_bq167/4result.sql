WITH pair_votes AS (
    /* how many distinct messages each user has up-voted another user on */
    SELECT
        "FromUserId"  AS giver_id,
        "ToUserId"    AS receiver_id,
        COUNT(DISTINCT "ForumMessageId") AS upvotes_given
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY giver_id, receiver_id
),
bidir AS (
    /* add the reciprocal (returned) count */
    SELECT
        pv1.giver_id,
        pv1.receiver_id,
        pv1.upvotes_given,
        COALESCE(pv2.upvotes_given, 0) AS upvotes_returned
    FROM pair_votes pv1
    LEFT JOIN pair_votes pv2
           ON pv1.giver_id   = pv2.receiver_id
          AND pv1.receiver_id = pv2.giver_id
),
ranked AS (
    /* attach usernames and rank by the required ordering */
    SELECT
        ug."UserName" AS giver_username,
        ur."UserName" AS receiver_username,
        b.upvotes_given  AS distinct_upvotes_received_by_receiver,
        b.upvotes_returned,
        ROW_NUMBER() OVER (ORDER BY b.upvotes_given DESC,
                                   b.upvotes_returned DESC) AS rn
    FROM bidir b
    JOIN META_KAGGLE.META_KAGGLE.USERS ug
         ON b.giver_id = ug."Id"
    JOIN META_KAGGLE.META_KAGGLE.USERS ur
         ON b.receiver_id = ur."Id"
)
SELECT
    giver_username,
    receiver_username,
    distinct_upvotes_received_by_receiver,
    upvotes_returned
FROM ranked
WHERE rn = 1;