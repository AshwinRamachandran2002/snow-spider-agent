SELECT DISTINCT "prefName" AS "name", "approvedSymbol", f.value:"element":"url"::STRING AS "url"
FROM "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."KNOWNDRUGSAGGREGATED",
     LATERAL FLATTEN(input => "urls":list) f
WHERE "diseaseId" = 'EFO_0007416' AND "phase" = 3.0