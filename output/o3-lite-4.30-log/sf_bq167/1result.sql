WITH pair_votes AS (
    /* count distinct forum‑message up‑votes one user gave another
       (exclude the system account −1) */
    SELECT
        "FromUserId"  AS upvoter_id,
        "ToUserId"    AS recipient_id,
        COUNT(DISTINCT "ForumMessageId") AS upvotes_given
    FROM "META_KAGGLE"."META_KAGGLE"."FORUMMESSAGEVOTES"
    WHERE "FromUserId" <> -1
      AND "ToUserId"   <> -1
    GROUP BY "FromUserId", "ToUserId"
),
paired AS (
    /* attach the reverse direction to know how many votes were returned */
    SELECT
        a.upvoter_id,
        a.recipient_id,
        a.upvotes_given,
        COALESCE(b.upvotes_given, 0) AS upvotes_returned
    FROM pair_votes a
    LEFT JOIN pair_votes b
           ON  b.upvoter_id  = a.recipient_id
           AND b.recipient_id = a.upvoter_id
)
SELECT
    u1."UserName"            AS upvoter_username,
    u2."UserName"            AS recipient_username,
    paired.upvotes_given,
    paired.upvotes_returned
FROM paired
JOIN "META_KAGGLE"."META_KAGGLE"."USERS" u1
  ON u1."Id" = paired.upvoter_id
JOIN "META_KAGGLE"."META_KAGGLE"."USERS" u2
  ON u2."Id" = paired.recipient_id
WHERE paired.upvotes_returned > 0
ORDER BY
      paired.upvotes_given    DESC NULLS LAST,
      paired.upvotes_returned DESC NULLS LAST
LIMIT 1;