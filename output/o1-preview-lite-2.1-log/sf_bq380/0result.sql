SELECT
  u."UserName",
  COALESCE(r."Upvotes_Received", 0) AS "Upvotes_Received",
  COALESCE(g."Upvotes_Given", 0) AS "Upvotes_Given"
FROM "META_KAGGLE"."META_KAGGLE"."USERS" u
LEFT JOIN (
  SELECT "ToUserId", COUNT(*) AS "Upvotes_Received"
  FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
  GROUP BY "ToUserId"
) r ON u."Id" = r."ToUserId"
LEFT JOIN (
  SELECT "FromUserId", COUNT(*) AS "Upvotes_Given"
  FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
  GROUP BY "FromUserId"
) g ON u."Id" = g."FromUserId"
ORDER BY r."Upvotes_Received" DESC NULLS LAST
LIMIT 3;