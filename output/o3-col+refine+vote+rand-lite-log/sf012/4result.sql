-- Total building- and contents-damage dollars for NFIP claims in
-- the “City Of New York” community, by calendar year of loss (2010-2019)

SELECT
    EXTRACT(YEAR FROM "DATE_OF_LOSS")                    AS "loss_year",
    SUM("BUILDING_DAMAGE_AMOUNT")                        AS "total_building_damage_usd",
    SUM("CONTENTS_DAMAGE_AMOUNT")                        AS "total_contents_damage_usd"
FROM WEATHER__ENVIRONMENT.CYBERSYN.FEMA_NATIONAL_FLOOD_INSURANCE_PROGRAM_CLAIM_INDEX
WHERE "NFIP_COMMUNITY_NAME" = 'City Of New York'
  AND "DATE_OF_LOSS" BETWEEN '2010-01-01' AND '2019-12-31'
GROUP BY 1
ORDER BY 1;