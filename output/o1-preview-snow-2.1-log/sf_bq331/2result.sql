SELECT 
  u."Id" AS "UserId", 
  u."UserName", 
  u."DisplayName", 
  ROUND(user_avg."AverageScore", 4) AS "Average_Message_Score", 
  ROUND(ABS(user_avg."AverageScore" - overall_avg."OverallAverageScore"), 4) AS "Absolute_Difference"
FROM (
  SELECT mv."PostUserId" AS "UserId", AVG(mv."VoteCount") AS "AverageScore"
  FROM (
    SELECT m."Id", m."PostUserId", COUNT(v."Id") AS "VoteCount"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGES" m
    LEFT JOIN "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES" v
      ON m."Id" = v."ForumMessageId"
    GROUP BY m."Id", m."PostUserId"
  ) mv
  GROUP BY mv."PostUserId"
) user_avg
CROSS JOIN (
  SELECT AVG("VoteCount") AS "OverallAverageScore"
  FROM (
    SELECT m."Id", COUNT(v."Id") AS "VoteCount"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGES" m
    LEFT JOIN "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES" v
      ON m."Id" = v."ForumMessageId"
    GROUP BY m."Id"
  ) s
) overall_avg
JOIN "META_KAGGLE"."META_KAGGLE"."USERS" u
  ON user_avg."UserId" = u."Id"
ORDER BY "Absolute_Difference" ASC, u."Id"
LIMIT 3;