-- Task: List up to 100 claims reported under the National Flood Insurance Program for the NFIP community named 'City Of New York' between 2010 and 2019, showing the year of loss, building damage amount, and contents damage amount.

SELECT
    YEAR("claims"."DATE_OF_LOSS") AS "YEAR_OF_LOSS",
    "claims"."BUILDING_DAMAGE_AMOUNT",
    "claims"."CONTENTS_DAMAGE_AMOUNT"
FROM WEATHER__ENVIRONMENT.CYBERSYN."FEMA_NATIONAL_FLOOD_INSURANCE_PROGRAM_CLAIM_INDEX" "claims"
WHERE
    "claims"."NFIP_COMMUNITY_NAME" = 'City Of New York'
    AND YEAR("claims"."DATE_OF_LOSS") >= 2010
    AND YEAR("claims"."DATE_OF_LOSS") <= 2019
ORDER BY "YEAR_OF_LOSS"
LIMIT 100;