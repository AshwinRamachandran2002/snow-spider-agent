WITH clinical AS (
    -- BRCA patients with known histological type
    SELECT
        "bcr_patient_barcode"        AS "ParticipantBarcode",
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
mutation_patients AS (
    -- Reliable CDH1 mutation calls (PASS only)
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER" = 'PASS'
),
patients AS (
    -- Flag patients as mutated / not‑mutated
    SELECT
        c."ParticipantBarcode",
        c."histological_type",
        CASE WHEN m."ParticipantBarcode" IS NOT NULL
             THEN 'MUTATED'
             ELSE 'NOT_MUTATED'
        END                           AS "mutation_status"
    FROM clinical c
    LEFT JOIN mutation_patients m
           ON c."ParticipantBarcode" = m."ParticipantBarcode"
),
cont AS (
    -- Contingency table
    SELECT
        "histological_type",
        "mutation_status",
        COUNT(*)                      AS obs
    FROM patients
    GROUP BY "histological_type", "mutation_status"
),
row_totals AS (
    -- Keep histological types with >10 patients
    SELECT "histological_type",
           SUM(obs)                  AS row_total
    FROM cont
    GROUP BY "histological_type"
    HAVING SUM(obs) > 10
),
filtered_cont AS (
    SELECT c.*
    FROM cont            c
    JOIN row_totals      r USING ("histological_type")
),
col_totals AS (
    -- Keep mutation-status columns with >10 patients
    SELECT "mutation_status",
           SUM(obs)                  AS col_total
    FROM filtered_cont
    GROUP BY "mutation_status"
    HAVING SUM(obs) > 10
),
final_cont AS (
    SELECT f.*
    FROM filtered_cont  f
    JOIN col_totals     ct USING ("mutation_status")
),
grand_total AS (
    SELECT SUM(obs) AS total
    FROM   final_cont
),
expected_vals AS (
    -- Expected counts for each cell
    SELECT
        fc."histological_type",
        fc."mutation_status",
        fc.obs,
        (rt.row_total * ct.col_total) / gt.total    AS expected
    FROM   final_cont  fc
    JOIN   row_totals  rt USING ("histological_type")
    JOIN   col_totals  ct USING ("mutation_status")
    CROSS JOIN grand_total gt
),
chi_square_calc AS (
    -- Chi‑square statistic
    SELECT
        SUM( POWER(obs - expected, 2) / expected ) AS chi_square_value
    FROM expected_vals
)
SELECT chi_square_value
FROM   chi_square_calc;