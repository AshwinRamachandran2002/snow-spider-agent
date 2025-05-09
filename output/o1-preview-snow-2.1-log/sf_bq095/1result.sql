SELECT DISTINCT m."name", t."approvedSymbol",
k."urls":list[0]:element:url::STRING AS "url"
FROM "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."KNOWNDRUGSAGGREGATED" k
JOIN "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."MOLECULE" m ON m."id" = k."drugId"
JOIN "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."TARGETS" t ON t."id" = k."targetId"
WHERE k."diseaseId" = 'EFO_0007416' AND k."phase" = 3.0;