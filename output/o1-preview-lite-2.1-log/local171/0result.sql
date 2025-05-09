SELECT
    "years_of_service",
    COUNT(*) AS "Number_of_Legislators"
FROM
    (
        SELECT
            lt."id_bioguide",
            CAST(((julianday(MAX(lt."term_end")) - julianday(MIN(lt."term_start"))) / 365.25) AS INTEGER) AS "years_of_service"
        FROM
            "legislators_terms" lt
        INNER JOIN
            "legislators" l ON lt."id_bioguide" = l."id_bioguide"
        WHERE
            l."gender" = 'M' AND lt."state" = 'LA'
        GROUP BY
            lt."id_bioguide"
    ) sub
WHERE
    "years_of_service" > 30 AND "years_of_service" < 50
GROUP BY
    "years_of_service"
ORDER BY
    "years_of_service"
;