SELECT U."UserName", UR."Upvotes_Received", COALESCE(UG."Upvotes_Given", 0) AS "Upvotes_Given"
FROM "META_KAGGLE"."META_KAGGLE"."USERS" U
JOIN (
    SELECT "ToUserId", COUNT(*) AS "Upvotes_Received"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    GROUP BY "ToUserId"
) UR ON U."Id" = UR."ToUserId"
LEFT JOIN (
    SELECT "FromUserId", COUNT(*) AS "Upvotes_Given"
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    GROUP BY "FromUserId"
) UG ON U."Id" = UG."FromUserId"
ORDER BY UR."Upvotes_Received" DESC NULLS LAST
LIMIT 3;