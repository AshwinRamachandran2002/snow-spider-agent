WITH legislator_service AS (
    SELECT
        l."id_bioguide",
        ROUND(
            (DATEDIFF(day, MIN(TO_DATE(lt."term_start", 'YYYY-MM-DD')), MAX(TO_DATE(lt."term_end", 'YYYY-MM-DD'))) ) / 365.25,
            4
        ) AS years_of_service
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS l
        ON lt."id_bioguide" = l."id_bioguide"
    WHERE l."gender" = 'M' AND lt."state" = 'LA'
    GROUP BY l."id_bioguide"
)
SELECT years_of_service AS "Years_of_Service", COUNT(*) AS "Number_of_Legislators"
FROM legislator_service
WHERE years_of_service > 30 AND years_of_service < 50
GROUP BY years_of_service
ORDER BY "Years_of_Service";