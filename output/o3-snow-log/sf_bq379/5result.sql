WITH "psoriasis" AS (
    SELECT "id" AS "disease_id"
    FROM "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."DISEASES"
    WHERE LOWER("name") = 'psoriasis'
    LIMIT 1
),
"ps_assoc" AS (
    SELECT a."targetId",
           a."score"
    FROM "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."ASSOCIATIONBYOVERALLDIRECT" a
    JOIN "psoriasis" p
      ON a."diseaseId" = p."disease_id"
),
"stats" AS (
    SELECT AVG("score") AS "mean_score"
    FROM "ps_assoc"
),
"closest" AS (
    SELECT p."targetId",
           p."score",
           ABS(p."score" - s."mean_score") AS "diff"
    FROM "ps_assoc" p
    CROSS JOIN "stats" s
    ORDER BY "diff" ASC NULLS LAST
    LIMIT 1
)
SELECT t."approvedSymbol"
FROM "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."TARGETS" t
JOIN "closest" c
  ON t."id" = c."targetId";