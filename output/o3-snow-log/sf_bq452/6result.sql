WITH variant_calls AS (  -- expand every genotype allele on chr12
    SELECT
        v."start"          AS start_pos,
        v."end"            AS end_pos,
        c.value:"call_set_name"::string  AS sample_id,
        g.value::int       AS allele_value
    FROM _1000_GENOMES._1000_GENOMES."VARIANTS"  v
         ,LATERAL FLATTEN(input => v."call")                c
         ,LATERAL FLATTEN(input => c.value:"genotype")      g
    WHERE v."reference_name" = '12'
),
allele_flags AS (          -- mark case / control & allele type
    SELECT
        start_pos,
        end_pos,
        CASE WHEN si."Super_Population" = 'EAS' THEN 1 ELSE 0 END AS is_case,
        CASE WHEN allele_value > 0          THEN 1 ELSE 0 END AS is_alt
    FROM variant_calls vc
    JOIN _1000_GENOMES._1000_GENOMES."SAMPLE_INFO" si
          ON vc.sample_id = si."Sample"
),
allele_counts AS (         -- 2×2 table counts per variant
    SELECT
        start_pos,
        end_pos,
        SUM(CASE WHEN is_case = 1 AND is_alt = 1 THEN 1 ELSE 0 END) AS cases_alt,
        SUM(CASE WHEN is_case = 1 AND is_alt = 0 THEN 1 ELSE 0 END) AS cases_ref,
        SUM(CASE WHEN is_case = 0 AND is_alt = 1 THEN 1 ELSE 0 END) AS controls_alt,
        SUM(CASE WHEN is_case = 0 AND is_alt = 0 THEN 1 ELSE 0 END) AS controls_ref
    FROM allele_flags
    GROUP BY start_pos, end_pos
),
stats AS (                 -- totals & expected counts
    SELECT
        *,
        (cases_alt + cases_ref)                AS total_cases,
        (controls_alt + controls_ref)          AS total_controls,
        (cases_alt + controls_alt)             AS total_alt,
        (cases_ref + controls_ref)             AS total_ref
    FROM allele_counts
),
expected_ok AS (           -- discard variants with any expected cell < 5
    SELECT
        *,
        (total_cases   * total_alt    )::FLOAT / (total_cases + total_controls) AS exp_cases_alt,
        (total_cases   * total_ref    )::FLOAT / (total_cases + total_controls) AS exp_cases_ref,
        (total_controls* total_alt    )::FLOAT / (total_cases + total_controls) AS exp_controls_alt,
        (total_controls* total_ref    )::FLOAT / (total_cases + total_controls) AS exp_controls_ref
    FROM stats
    WHERE LEAST(
            (total_cases   * total_alt   )::FLOAT / (total_cases + total_controls),
            (total_cases   * total_ref   )::FLOAT / (total_cases + total_controls),
            (total_controls* total_alt   )::FLOAT / (total_cases + total_controls),
            (total_controls* total_ref   )::FLOAT / (total_cases + total_controls)
          ) >= 5
),
chi_sq AS (                 -- Yates-corrected χ²
    SELECT
        start_pos,
        end_pos,
        ROUND(
              ( (total_cases + total_controls)
                * POWER(
                        GREATEST( ABS(cases_alt*controls_ref - cases_ref*controls_alt)
                                  - (total_cases + total_controls)/2 , 0)
                        , 2)
              )
              / ( total_cases * total_controls * total_alt * total_ref )
        , 4) AS chi_squared_score
    FROM expected_ok
)
SELECT
    start_pos AS "start",
    end_pos   AS "end",
    chi_squared_score
FROM chi_sq
WHERE chi_squared_score >= 29.71679
ORDER BY chi_squared_score DESC NULLS LAST;