SELECT total_years_of_service AS "Years_of_Service",
       COUNT(*) AS "Number_of_Legislators"
FROM (
    SELECT l."id_bioguide", 
           SUM(DATEDIFF(year, TO_DATE(lt."term_start", 'YYYY-MM-DD'), TO_DATE(lt."term_end", 'YYYY-MM-DD'))) AS total_years_of_service
    FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS" l
    JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS" lt
        ON l."id_bioguide" = lt."id_bioguide"
    WHERE l."gender" = 'M' AND lt."state" = 'LA'
    GROUP BY l."id_bioguide"
    HAVING SUM(DATEDIFF(year, TO_DATE(lt."term_start", 'YYYY-MM-DD'), TO_DATE(lt."term_end", 'YYYY-MM-DD'))) > 30
       AND SUM(DATEDIFF(year, TO_DATE(lt."term_start", 'YYYY-MM-DD'), TO_DATE(lt."term_end", 'YYYY-MM-DD'))) < 50
) AS sub
GROUP BY total_years_of_service
ORDER BY total_years_of_service;