SELECT fu."UserName" AS "User1",
       tu."UserName" AS "User2",
       a."Upvotes" AS "Upvotes_from_User1_to_User2",
       b."Upvotes" AS "Upvotes_from_User2_to_User1"
FROM
  (SELECT "FromUserId", "ToUserId", COUNT(*) AS "Upvotes"
   FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
   GROUP BY "FromUserId", "ToUserId") a
JOIN
  (SELECT "FromUserId", "ToUserId", COUNT(*) AS "Upvotes"
   FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES
   GROUP BY "FromUserId", "ToUserId") b
ON a."FromUserId" = b."ToUserId" AND a."ToUserId" = b."FromUserId"
JOIN META_KAGGLE.META_KAGGLE.USERS fu ON a."FromUserId" = fu."Id"
JOIN META_KAGGLE.META_KAGGLE.USERS tu ON a."ToUserId" = tu."Id"
WHERE a."FromUserId" < a."ToUserId"
ORDER BY (a."Upvotes" + b."Upvotes") DESC NULLS LAST
LIMIT 1;