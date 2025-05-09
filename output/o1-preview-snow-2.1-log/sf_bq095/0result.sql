SELECT
    m."name" AS "Drug Name",
    t."approvedSymbol" AS "Target Approved Symbol",
    u.value:"element":"url"::STRING AS "Clinical Trial URL"
FROM
    "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."KNOWNDRUGSAGGREGATED" kd
JOIN
    "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."MOLECULE" m
    ON kd."drugId" = m."id"
JOIN
    "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."TARGETS" t
    ON kd."targetId" = t."id",
LATERAL FLATTEN(input => kd."urls":list) u
WHERE
    kd."diseaseId" = 'EFO_0007416' AND kd."status" = 'Completed';