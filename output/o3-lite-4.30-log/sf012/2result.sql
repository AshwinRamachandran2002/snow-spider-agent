SELECT
    EXTRACT(year FROM "DATE_OF_LOSS")                                          AS "year_of_loss",
    CAST(ROUND(SUM("BUILDING_DAMAGE_AMOUNT"), 4)  AS NUMBER(38,4))            AS "total_building_damage",
    CAST(ROUND(SUM("CONTENTS_DAMAGE_AMOUNT"), 4)  AS NUMBER(38,4))            AS "total_contents_damage"
FROM
    WEATHER__ENVIRONMENT.CYBERSYN.FEMA_NATIONAL_FLOOD_INSURANCE_PROGRAM_CLAIM_INDEX
WHERE
    "NFIP_COMMUNITY_NAME" = 'City Of New York'
    AND "DATE_OF_LOSS" >= '2010-01-01'
    AND "DATE_OF_LOSS" <  '2020-01-01'
GROUP BY
    EXTRACT(year FROM "DATE_OF_LOSS")
ORDER BY
    "year_of_loss";