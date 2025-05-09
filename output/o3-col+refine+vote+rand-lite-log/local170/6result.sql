/*  State abbreviations whose male and female legislator cohorts each keep at least
    one member “still serving” on 31-Dec of years 0,2,4,6,8 and 10 after the
    legislator’s very first term-start date.                                       */

WITH
-- six anniversary offsets (in years)
offsets(offset_yr) AS (
    SELECT 0  UNION ALL  SELECT 2 UNION ALL
    SELECT 4  UNION ALL  SELECT 6 UNION ALL
    SELECT 8  UNION ALL  SELECT 10
),

/* first term information for every legislator:
   - first_term_start : earliest term_start
   - state            : state in that first term                                  */
first_term_info AS (
    SELECT ft.id_bioguide,
           MIN(t.state)                      AS state,          -- pick a state value
           ft.first_term_start
    FROM (
            SELECT id_bioguide,
                   MIN(term_start) AS first_term_start
            FROM   legislators_terms
            GROUP  BY id_bioguide
         ) ft
    JOIN legislators_terms t
         ON  t.id_bioguide = ft.id_bioguide
         AND t.term_start  = ft.first_term_start
    GROUP BY ft.id_bioguide, ft.first_term_start
),

/* for every legislator × offset, see if he/she was in office on 31-Dec
   of (first_term_year + offset)                                                   */
retention AS (
    SELECT f.state,
           l.gender,
           o.offset_yr,
           COUNT(DISTINCT f.id_bioguide) AS retained_cnt
    FROM   first_term_info         f
    JOIN   legislators             l ON l.id_bioguide = f.id_bioguide
    JOIN   offsets                 o
    JOIN   legislators_terms       t ON t.id_bioguide = f.id_bioguide
        AND date( (CAST(strftime('%Y',f.first_term_start) AS INTEGER)+o.offset_yr)
                  ||'-12-31'
                )
            BETWEEN t.term_start AND t.term_end
    WHERE  l.gender IN ('M','F')
    GROUP  BY f.state, l.gender, o.offset_yr
),

/* keep gender–state pairs that have non-zero retention at all six checkpoints     */
gender_state_ok AS (
    SELECT state,
           gender
    FROM   retention
    GROUP  BY state, gender
    HAVING COUNT(offset_yr)=6            -- all six anniversaries present
       AND MIN(retained_cnt) > 0         -- every one has at least one legislator
)

/* final states where BOTH genders satisfy the above                              */
SELECT state
FROM   gender_state_ok
GROUP  BY state
HAVING COUNT(DISTINCT gender)=2;          -- need both M and F