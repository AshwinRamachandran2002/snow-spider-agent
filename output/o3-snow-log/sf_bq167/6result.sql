WITH directional AS (   -- votes counted for every ordered user-pair
    SELECT
        "FromUserId"                       AS "from_user",
        "ToUserId"                         AS "to_user",
        COUNT(DISTINCT "ForumMessageId")   AS "vote_cnt"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "from_user", "to_user"
),
paired AS (             -- bring the two directions together
    SELECT
        d1."from_user"         AS "user_a",
        d1."to_user"           AS "user_b",
        d1."vote_cnt"          AS "a_to_b",          -- up-votes A gave to B
        COALESCE(d2."vote_cnt",0) AS "b_to_a"        -- up-votes B gave to A
    FROM directional d1
    LEFT JOIN directional d2
           ON d2."from_user" = d1."to_user"
          AND d2."to_user"   = d1."from_user"
),
named AS (               -- attach Kaggle user names
    SELECT
        ua."UserName"          AS "user_a_name",
        ub."UserName"          AS "user_b_name",
        p."a_to_b"             AS "upvotes_a_received",
        p."b_to_a"             AS "upvotes_b_received"
    FROM paired p
    JOIN META_KAGGLE.META_KAGGLE.USERS ua
          ON ua."Id" = p."user_a"
    JOIN META_KAGGLE.META_KAGGLE.USERS ub
          ON ub."Id" = p."user_b"
)
SELECT *
FROM   named
ORDER  BY "upvotes_a_received" DESC NULLS LAST,   -- highest distinct up-votes
          "upvotes_b_received" DESC NULLS LAST    -- then most returned
LIMIT 1;    -- top pair only