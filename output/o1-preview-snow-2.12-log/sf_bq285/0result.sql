SELECT "zip_code"
FROM "FDA"."FDIC_BANKS"."LOCATIONS"
WHERE "state_name" = 'Florida'
GROUP BY "zip_code"
ORDER BY COUNT(DISTINCT "fdic_certificate_number") DESC NULLS LAST
LIMIT 1;