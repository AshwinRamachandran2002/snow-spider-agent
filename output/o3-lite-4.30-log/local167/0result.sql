WITH female_legislators AS (
    SELECT id_bioguide
    FROM legislators
    WHERE gender = 'F'
),
dec31_legislators AS (
    /* female legislators who had at least one term spanning any December 31 */
    SELECT DISTINCT lt.id_bioguide
    FROM legislators_terms lt
    JOIN female_legislators fl ON fl.id_bioguide = lt.id_bioguide
    WHERE date(lt.term_end) >= date(substr(lt.term_start,1,4) || '-12-31')
),
first_term_states AS (
    /* state each legislator first represented */
    SELECT id_bioguide, state
    FROM legislators_terms
    WHERE term_number = 0
)
SELECT
    fts.state AS state_abbreviation,
    COUNT(*)  AS female_legislator_count
FROM dec31_legislators dl
JOIN first_term_states fts ON fts.id_bioguide = dl.id_bioguide
GROUP BY fts.state
ORDER BY female_legislator_count DESC, state_abbreviation ASC
LIMIT 1;