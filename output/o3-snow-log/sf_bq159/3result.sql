WITH brca_clinical AS (
    /*  BRCA patients with known histology                                   */
    SELECT
        "bcr_patient_barcode"            AS participant,
        "histological_type"              AS hist_type
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
cdh1_mutated AS (
    /*  Reliable (PASS) CDH1 mutations in BRCA tumours                       */
    SELECT DISTINCT
        "ParticipantBarcode"             AS participant
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER" = 'PASS'
),
mutation_status AS (
    /*  Tag each patient as Mutated / Not-Mutated                            */
    SELECT
        c.participant,
        c.hist_type,
        CASE WHEN m.participant IS NOT NULL
             THEN 'Mutated'
             ELSE 'Not_Mutated'
        END                              AS mut_status
    FROM brca_clinical c
    LEFT JOIN cdh1_mutated m
           ON c.participant = m.participant
),
counts AS (
    /*  Contingency table of observed counts                                 */
    SELECT
        hist_type,
        mut_status,
        COUNT(*)                         AS obs
    FROM mutation_status
    GROUP BY hist_type, mut_status
),
row_totals AS (
    SELECT hist_type, SUM(obs) AS row_tot FROM counts GROUP BY hist_type
),
col_totals AS (
    SELECT mut_status, SUM(obs) AS col_tot FROM counts GROUP BY mut_status
),
/*  Filter away marginal totals ≤ 10                                         */
valid_hist AS (
    SELECT hist_type FROM row_totals WHERE row_tot > 10
),
valid_mut  AS (
    SELECT mut_status FROM col_totals WHERE col_tot > 10
),
filtered_counts AS (
    SELECT c.*
    FROM counts c
    JOIN valid_hist vh ON c.hist_type  = vh.hist_type
    JOIN valid_mut  vm ON c.mut_status = vm.mut_status
),
row_totals_f AS (
    SELECT hist_type, SUM(obs) AS row_tot FROM filtered_counts GROUP BY hist_type
),
col_totals_f AS (
    SELECT mut_status, SUM(obs) AS col_tot FROM filtered_counts GROUP BY mut_status
),
grand_tot AS (
    SELECT SUM(obs) AS n_tot FROM filtered_counts
),
expected AS (
    /*  Expected counts under independence                                    */
    SELECT
        fc.hist_type,
        fc.mut_status,
        fc.obs,
        rt.row_tot,
        ct.col_tot,
        g.n_tot,
        (rt.row_tot * ct.col_tot) / g.n_tot    AS exp_cnt
    FROM filtered_counts fc
    JOIN row_totals_f rt ON fc.hist_type  = rt.hist_type
    JOIN col_totals_f ct ON fc.mut_status = ct.mut_status
    CROSS JOIN grand_tot g
),
chi_square AS (
    SELECT
        SUM( POWER(obs - exp_cnt, 2) / exp_cnt ) :: FLOAT AS chi_square_value
    FROM expected
)
SELECT chi_square_value
FROM chi_square;