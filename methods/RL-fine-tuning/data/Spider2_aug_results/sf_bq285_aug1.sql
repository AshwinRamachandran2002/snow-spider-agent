-- Task: Could you provide me with the number of bank institutions in each zip code in Florida?
SELECT "zip_code", COUNT(DISTINCT "fdic_certificate_number") AS "institution_count"
FROM "FDA"."FDIC_BANKS"."LOCATIONS"
WHERE "state_name" = 'Florida'
GROUP BY "zip_code";