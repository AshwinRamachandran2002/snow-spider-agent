SELECT u."UserName",
       COUNT(v."Id") AS "Total_upvotes_received",
       (SELECT COUNT(vg."Id")
        FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES vg
        WHERE vg."FromUserId" = u."Id") AS "Total_upvotes_given"
FROM META_KAGGLE.META_KAGGLE.USERS u
JOIN META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES v ON u."Id" = v."ToUserId"
GROUP BY u."UserName", u."Id"
ORDER BY "Total_upvotes_received" DESC NULLS LAST
LIMIT 3;