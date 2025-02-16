-- Task: Retrieve the approved symbol of the target gene that is directly associated with disease 'EFO_0000676' using evidence from the data source 'IMPC', and has the highest overall direct association score.
SELECT t."approvedSymbol"
FROM "OPEN_TARGETS_PLATFORM_2"."OPEN_TARGETS_PLATFORM"."TARGETS" t
JOIN "OPEN_TARGETS_PLATFORM_2"."OPEN_TARGETS_PLATFORM"."ASSOCIATIONBYOVERALLDIRECT" a
  ON t."id" = a."targetId"
JOIN "OPEN_TARGETS_PLATFORM_2"."OPEN_TARGETS_PLATFORM"."EVIDENCE" e
  ON a."targetId" = e."targetId" AND a."diseaseId" = e."diseaseId"
WHERE a."diseaseId" = 'EFO_0000676' AND LOWER(e."datasourceId") = 'impc'
ORDER BY a."score" DESC NULLS LAST
LIMIT 1;