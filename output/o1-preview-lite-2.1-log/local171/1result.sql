SELECT total_years_int AS Years_of_Service, COUNT(*) AS Number_of_Legislators
FROM (
    SELECT l."id_bioguide", l."full_name",
           (JULIANDAY(MAX(lt."term_end")) - JULIANDAY(MIN(lt."term_start"))) / 365.25 AS total_service_years,
           CAST ((JULIANDAY(MAX(lt."term_end")) - JULIANDAY(MIN(lt."term_start"))) / 365.25 AS INT) AS total_years_int
    FROM "legislators" AS l
    JOIN "legislators_terms" AS lt ON l."id_bioguide" = lt."id_bioguide"
    WHERE lt."state" = 'LA' AND l."gender" = 'M'
    GROUP BY l."id_bioguide"
    HAVING total_service_years > 30 AND total_service_years < 50
)
GROUP BY total_years_int
ORDER BY Years_of_Service;