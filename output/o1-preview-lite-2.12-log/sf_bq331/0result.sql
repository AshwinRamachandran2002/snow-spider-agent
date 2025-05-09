SELECT
    u."Id" AS "UserId",
    u."UserName",
    u."DisplayName",
    ROUND(ua."AverageMessageScore", 4) AS "Average_Message_Score",
    ROUND(ABS(ua."AverageMessageScore" - oa."OverallAverageMessageScore"), 4) AS "Absolute_Difference"
FROM
    (
        SELECT
            m."PostUserId",
            AVG(COALESCE(vv."VoteCount", 0)) AS "AverageMessageScore"
        FROM
            "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGES" m
            LEFT JOIN (
                SELECT
                    v."ForumMessageId",
                    COUNT(*) AS "VoteCount"
                FROM
                    "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES" v
                GROUP BY
                    v."ForumMessageId"
            ) vv ON m."Id" = vv."ForumMessageId"
        GROUP BY
            m."PostUserId"
    ) ua
    CROSS JOIN (
        SELECT
            AVG("VoteCount") AS "OverallAverageMessageScore"
        FROM (
            SELECT
                COUNT(v."Id") AS "VoteCount"
                FROM
                    "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGES" m
                    LEFT JOIN "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES" v
                        ON m."Id" = v."ForumMessageId"
                    GROUP BY
                        m."Id"
            ) sub
    ) oa
    INNER JOIN "META_KAGGLE"."META_KAGGLE"."USERS" u
        ON ua."PostUserId" = u."Id"
ORDER BY
    ABS(ua."AverageMessageScore" - oa."OverallAverageMessageScore") ASC
LIMIT 3;