WITH first_terms AS (
    -- earliest term for every legislator with known gender
    SELECT  lt.id_bioguide,
            CAST(substr(MIN(lt.term_start),1,4) AS INTEGER)      AS first_start_year,
            l.gender,
            lt.state
    FROM   legislators_terms lt
    JOIN   legislators        l  ON l.id_bioguide = lt.id_bioguide
    WHERE  l.gender IN ('M','F')
    GROUP  BY lt.id_bioguide
),
intervals(years) AS (VALUES (0),(2),(4),(6),(8),(10)),

cohort AS (
    -- one record per legislator per required anniversary
    SELECT  f.id_bioguide,
            f.state,
            f.gender,
            i.years,
            date(printf('%04d-12-31',f.first_start_year + i.years)) AS target_date
    FROM   first_terms f
    JOIN   intervals   i
),

retained AS (
    -- keep only rows where the legislator is still in office
    SELECT  c.state,
            c.gender,
            c.years
    FROM    cohort            c
    JOIN    legislators_terms lt
           ON lt.id_bioguide = c.id_bioguide
          AND date(lt.term_start)                       <= c.target_date
          AND date(COALESCE(lt.term_end,'9999-12-31'))  >= c.target_date
    GROUP   BY c.state, c.gender, c.years
),

valid_gender_state AS (
    -- gender/state combos that have >0 retained legislators for ALL 6 anniversaries
    SELECT  state,
            gender
    FROM    retained
    GROUP   BY state, gender
    HAVING  COUNT(*) = 6          -- one successful row for every interval
),

states_both AS (
    -- keep only states that satisfy the rule for BOTH genders
    SELECT  state
    FROM    valid_gender_state
    GROUP   BY state
    HAVING  COUNT(DISTINCT gender) = 2
)

SELECT DISTINCT state
FROM   states_both
ORDER BY state;