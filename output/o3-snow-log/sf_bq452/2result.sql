/* ---------------------------------------------------------------
   Chromosome-12 variants whose Yates-corrected χ² (EAS vs non-EAS)
   is ≥ 29.71679
---------------------------------------------------------------- */
WITH sample_pop AS (                     -- sample → super-population
    SELECT
        "Sample"            AS sample_id,
        "Super_Population"  AS super_pop
    FROM "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"
),

genotype_alleles AS (                    -- one row per allele
    SELECT
        v."start",
        v."end",
        sp.super_pop,
        CASE WHEN allele.value::INT = 0 THEN 'REF' ELSE 'ALT' END AS allele_type
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v,
         LATERAL FLATTEN(input => v."call")                c,      -- expand call array
         LATERAL FLATTEN(input => c.value:"genotype")      allele, -- expand genotype array
         sample_pop                                         sp     -- join to pop table
    WHERE v."reference_name" = '12'
      AND sp.sample_id = c.value:"call_set_name"::STRING
),

allele_counts AS (                       -- 2×2 observed counts
    SELECT
        "start",
        "end",
        SUM(IFF(super_pop = 'EAS', IFF(allele_type = 'REF',1,0), 0)) AS cases_ref,
        SUM(IFF(super_pop = 'EAS', IFF(allele_type = 'ALT',1,0), 0)) AS cases_alt,
        SUM(IFF(super_pop <> 'EAS', IFF(allele_type = 'REF',1,0), 0)) AS ctrls_ref,
        SUM(IFF(super_pop <> 'EAS', IFF(allele_type = 'ALT',1,0), 0)) AS ctrls_alt
    FROM genotype_alleles
    GROUP BY "start", "end"
),

totals AS (                              -- row/col/overall totals
    SELECT
        "start",
        "end",
        cases_ref,
        cases_alt,
        ctrls_ref,
        ctrls_alt,
        (cases_ref  + cases_alt)                 AS cases_tot,
        (ctrls_ref  + ctrls_alt)                 AS ctrls_tot,
        (cases_ref + cases_alt + ctrls_ref + ctrls_alt) AS grand_tot,
        (cases_ref + ctrls_ref)                  AS ref_tot,
        (cases_alt + ctrls_alt)                  AS alt_tot
    FROM allele_counts
),

stats AS (                               -- expected counts
    SELECT
        "start",
        "end",
        cases_ref,
        cases_alt,
        ctrls_ref,
        ctrls_alt,
        (cases_tot  * ref_tot / grand_tot)::FLOAT AS exp_cases_ref,
        (ctrls_tot  * ref_tot / grand_tot)::FLOAT AS exp_ctrls_ref,
        (cases_tot  * alt_tot / grand_tot)::FLOAT AS exp_cases_alt,
        (ctrls_tot  * alt_tot / grand_tot)::FLOAT AS exp_ctrls_alt
    FROM totals
    WHERE   exp_cases_ref  >= 5
        AND exp_ctrls_ref  >= 5
        AND exp_cases_alt  >= 5
        AND exp_ctrls_alt  >= 5
),

chi2 AS (                                -- Yates-corrected χ²
    SELECT
        "start",
        "end",
        (
            POWER(ABS(cases_ref  - exp_cases_ref)  - 0.5, 2) / exp_cases_ref  +
            POWER(ABS(ctrls_ref  - exp_ctrls_ref)  - 0.5, 2) / exp_ctrls_ref +
            POWER(ABS(cases_alt  - exp_cases_alt)  - 0.5, 2) / exp_cases_alt +
            POWER(ABS(ctrls_alt  - exp_ctrls_alt)  - 0.5, 2) / exp_ctrls_alt
        ) AS chi2_score
    FROM stats
)

SELECT
    "start",
    "end",
    chi2_score
FROM chi2
WHERE chi2_score >= 29.71679
ORDER BY chi2_score DESC NULLS LAST;