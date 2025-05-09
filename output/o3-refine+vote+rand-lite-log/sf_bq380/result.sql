WITH "received" AS (            -- up‑votes a user has received
    SELECT
        "ToUserId"                      AS "UserId",
        COUNT(DISTINCT "Id")            AS "ReceivedUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "ToUserId" IS NOT NULL
    GROUP BY "ToUserId"
),
"given" AS (                   -- up‑votes a user has given
    SELECT
        "FromUserId"                    AS "UserId",
        COUNT(DISTINCT "Id")            AS "GivenUpvotes"
    FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
    WHERE "FromUserId" IS NOT NULL
    GROUP BY "FromUserId"
),
"combined" AS (                -- bring everything together with the user name
    SELECT
        u."UserName",
        r."ReceivedUpvotes",
        COALESCE(g."GivenUpvotes", 0)   AS "GivenUpvotes"
    FROM "received" r
    LEFT JOIN "given" g
           ON r."UserId" = g."UserId"
    LEFT JOIN META_KAGGLE.META_KAGGLE.USERS u
           ON r."UserId" = u."Id"
)
SELECT
    "UserName",
    "ReceivedUpvotes",
    "GivenUpvotes"
FROM "combined"
ORDER BY
    "ReceivedUpvotes" DESC NULLS LAST,   -- primary sort: most up‑votes received
    "UserName"                           -- secondary sort to keep order stable
FETCH FIRST 3 ROWS ONLY;                 -- top‑3 users