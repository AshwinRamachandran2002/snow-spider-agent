WITH votes_received AS (
    SELECT 
        "ToUserId"                      AS "UserId",
        COUNT(DISTINCT "Id")            AS "TotalReceivedUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "ToUserId"
),
votes_given AS (
    SELECT 
        "FromUserId"                    AS "UserId",
        COUNT(DISTINCT "Id")            AS "TotalGivenUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    GROUP BY "FromUserId"
),
user_totals AS (
    SELECT
        u."UserName",
        r."TotalReceivedUpvotes",
        COALESCE(g."TotalGivenUpvotes", 0) AS "TotalGivenUpvotes"
    FROM META_KAGGLE.META_KAGGLE.USERS                u
    JOIN votes_received                              r ON u."Id" = r."UserId"
    LEFT JOIN votes_given                            g ON u."Id" = g."UserId"
)
SELECT
    "UserName",
    "TotalReceivedUpvotes",
    "TotalGivenUpvotes"
FROM user_totals
ORDER BY 
    "TotalReceivedUpvotes" DESC NULLS LAST,
    "UserName"              ASC
LIMIT 3;