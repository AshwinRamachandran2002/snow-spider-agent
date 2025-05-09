WITH CA_PUBLICATIONS AS
(
    /* 1.  Keep only Canadian publications (CA) issued between 1960‑01‑01 and 2020‑12‑31
          that list at least one inventor                                        */
    SELECT
        "publication_number",
        /* publication_date is in YYYYMMDD numeric form → convert to 4‑digit year */
        FLOOR("publication_date" / 10000)  AS "pub_year",
        ARRAY_SIZE("inventor")              AS "num_inventors"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"      = 'CA'
      AND "publication_date"  BETWEEN 19600101 AND 20201231
      AND "inventor"          IS NOT NULL
      AND ARRAY_SIZE("inventor") > 0
),

PERIODIZED AS
(
    /* 2.  Assign each publication to a 5‑year bucket whose first year is
          1960, 1965, 1970 … 2020 (inclusive).                                */
    SELECT
        "publication_number",
        "num_inventors",
        1960 + 5 * FLOOR( ("pub_year" - 1960) / 5 )          AS "start_year"
    FROM CA_PUBLICATIONS
    WHERE "pub_year" BETWEEN 1960 AND 2020
)

SELECT
    CONCAT("start_year", '-', "start_year" + 4)  AS "five_year_period",
    COUNT(*)                                     AS "publication_count",
    ROUND(AVG("num_inventors"), 2)               AS "avg_inventors_per_patent"
FROM PERIODIZED
GROUP BY "start_year"
ORDER BY "start_year";