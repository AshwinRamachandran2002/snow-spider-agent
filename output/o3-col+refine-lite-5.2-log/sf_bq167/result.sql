WITH agg AS (
    SELECT
        "FromUserId",
        "ToUserId",
        COUNT(DISTINCT "ForumMessageId") AS "vote_cnt"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId", "ToUserId"
)

SELECT
    ua."UserName"                              AS "UserA_UserName",
    ub."UserName"                              AS "UserB_UserName",
    a."vote_cnt"                               AS "A_to_B_votes",
    COALESCE(b."vote_cnt", 0)                  AS "B_to_A_votes"
FROM agg a
LEFT JOIN agg b
       ON  b."FromUserId" = a."ToUserId"
       AND b."ToUserId"   = a."FromUserId"
JOIN META_KAGGLE.META_KAGGLE.USERS ua
     ON ua."Id" = a."FromUserId"
JOIN META_KAGGLE.META_KAGGLE.USERS ub
     ON ub."Id" = a."ToUserId"
ORDER BY a."vote_cnt" DESC NULLS LAST,
         COALESCE(b."vote_cnt", 0) DESC NULLS LAST
LIMIT 1;