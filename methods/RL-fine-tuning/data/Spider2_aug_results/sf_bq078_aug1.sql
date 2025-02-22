-- Task: Retrieve the approved symbols of up to 100 target genes associated with the disease 'EFO_0000676'.
SELECT t."approvedSymbol"
FROM "OPEN_TARGETS_PLATFORM_2"."OPEN_TARGETS_PLATFORM"."TARGETS" t
JOIN "OPEN_TARGETS_PLATFORM_2"."OPEN_TARGETS_PLATFORM"."ASSOCIATIONBYOVERALLDIRECT" a
      ON t."id" = a."targetId"
WHERE a."diseaseId" = 'EFO_0000676'
LIMIT 100;