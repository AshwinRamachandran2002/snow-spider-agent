SELECT
    EXTRACT(year FROM claims."DATE_OF_LOSS") AS "Year",
    ROUND(SUM(claims."AMOUNT_PAID_ON_BUILDING_CLAIM"), 4) AS "Total_Building_Damage_Amount",
    ROUND(SUM(claims."AMOUNT_PAID_ON_CONTENTS_CLAIM"), 4) AS "Total_Contents_Damage_Amount"
FROM
    WEATHER__ENVIRONMENT.CYBERSYN.FEMA_NATIONAL_FLOOD_INSURANCE_PROGRAM_CLAIM_INDEX AS claims
JOIN
    WEATHER__ENVIRONMENT.CYBERSYN.GEOGRAPHY_INDEX AS geo
ON
    claims."COUNTY_GEO_ID" = geo."GEO_ID"
WHERE
    geo."GEO_NAME" IN ('New York County', 'Kings County', 'Queens County', 'Bronx County', 'Richmond County')
    AND claims."DATE_OF_LOSS" BETWEEN '2010-01-01' AND '2019-12-31'
GROUP BY
    "Year"
ORDER BY
    "Year";