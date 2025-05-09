/*  -----------------------------------------------------------
    Frequency of CNV sub-types per cytoband for TCGA-KIRC
    ----------------------------------------------------------- */
WITH per_band AS (    -- 1) max CN for every band in every case
    SELECT
        s."project_short_name",        -- acts as case identifier here
        s."chromosome",
        b."cytoband_name",
        MAX(s."copy_number") AS "max_copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38 b
      ON  s."chromosome" = b."chromosome"
      AND s."end_pos"   >= b."hg38_start"
      AND s."start_pos" <= b."hg38_stop"
    WHERE s."project_short_name" = 'TCGA-KIRC'
    GROUP BY
        s."project_short_name",
        s."chromosome",
        b."cytoband_name"
),
classified AS (       -- 2) translate max CN to CNV class
    SELECT
        "project_short_name",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN "max_copy_number" > 3 THEN 'Amplification'
            WHEN "max_copy_number" = 3 THEN 'Gain'
            WHEN "max_copy_number" = 2 THEN 'Normal'
            WHEN "max_copy_number" = 1 THEN 'Heterozygous Deletion'
            WHEN "max_copy_number" = 0 THEN 'Homozygous Deletion'
            ELSE 'Other'
        END AS "cnv_class"
    FROM per_band
),
total_cases AS (      -- 3) denominator for percentages
    SELECT COUNT(DISTINCT "project_short_name") AS n_cases
    FROM classified
)
SELECT                 -- 4) frequency of each CNV class per band
    c."chromosome",
    c."cytoband_name",
    c."cnv_class",
    ROUND(
        COUNT(DISTINCT c."project_short_name") * 100.0 / t.n_cases,
        4
    ) AS "percentage_of_cases"
FROM classified c
CROSS JOIN total_cases t
GROUP BY
    c."chromosome",
    c."cytoband_name",
    c."cnv_class",
    t.n_cases
ORDER BY               -- 5) requested ordering
    c."chromosome",
    c."cytoband_name";