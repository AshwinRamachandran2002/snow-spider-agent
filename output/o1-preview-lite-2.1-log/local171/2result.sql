SELECT CAST(sub."years_of_service" AS INTEGER) AS "Years_of_Service", COUNT(*) AS "Number_of_Legislators"
FROM (
    SELECT lt."id_bioguide",
           (julianday(MAX(lt."term_end")) - julianday(MIN(lt."term_start"))) / 365.25 AS "years_of_service"
    FROM "legislators_terms" lt
    JOIN "legislators" l ON lt."id_bioguide" = l."id_bioguide"
    WHERE l."gender" = 'M' AND lt."state" = 'LA'
    GROUP BY lt."id_bioguide"
) sub
WHERE sub."years_of_service" > 30 AND sub."years_of_service" < 50
GROUP BY "Years_of_Service"
ORDER BY "Years_of_Service";