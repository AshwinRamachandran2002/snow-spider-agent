SELECT TOP 3
    u."Id" AS "UserId",
    u."UserName",
    u."DisplayName",
    ROUND(AVG(COALESCE(v."VoteCount", 0)), 4) AS "Average_Message_Score",
    ROUND(ABS(ROUND(AVG(COALESCE(v."VoteCount", 0)), 4) - overall_avg."OverallAverageScore"), 4) AS "Absolute_Difference"
FROM
    META_KAGGLE.META_KAGGLE.USERS u
JOIN
    META_KAGGLE.META_KAGGLE.FORUMMESSAGES m ON u."Id" = m."PostUserId"
LEFT JOIN
    (
        SELECT "ForumMessageId", COUNT(*) AS "VoteCount"
        FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
        GROUP BY "ForumMessageId"
    ) v ON m."Id" = v."ForumMessageId"
CROSS JOIN
    (
        SELECT ROUND(AVG(COALESCE(MessageVotes."VoteCount", 0)), 4) AS "OverallAverageScore"
        FROM (
            SELECT m."Id" AS "ForumMessageId", COALESCE(v."VoteCount", 0) AS "VoteCount"
            FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGES m
            LEFT JOIN (
                SELECT "ForumMessageId", COUNT(*) AS "VoteCount"
                FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
                GROUP BY "ForumMessageId"
            ) v ON m."Id" = v."ForumMessageId"
        ) AS MessageVotes
    ) overall_avg
GROUP BY
    u."Id", u."UserName", u."DisplayName", overall_avg."OverallAverageScore"
ORDER BY
    "Absolute_Difference" ASC;