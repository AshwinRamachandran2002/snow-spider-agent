/*  Cytobands on chromosome 1 whose frequencies of Amplification (CN>3),
    Gain (CN=3) and Heterozygous-Deletion (CN=1) all rank within the
    top-11 in the TCGA-KIRC allelic-segment dataset                          */

WITH amp AS (   -- Top-11 cytobands for Amplifications
    SELECT c."cytoband_name"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38                                   c
      ON s."chromosome" = c."chromosome"
     AND s."start_pos"  <= c."hg38_stop"
     AND s."end_pos"    >= c."hg38_start"
    WHERE s."chromosome" = 'chr1'
      AND s."copy_number" > 3                       -- Amplification
    GROUP BY c."cytoband_name"
    QUALIFY RANK() OVER (ORDER BY COUNT(*) DESC NULLS LAST) <= 11
),
gain AS (       -- Top-11 cytobands for Gains
    SELECT c."cytoband_name"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38                                   c
      ON s."chromosome" = c."chromosome"
     AND s."start_pos"  <= c."hg38_stop"
     AND s."end_pos"    >= c."hg38_start"
    WHERE s."chromosome" = 'chr1'
      AND s."copy_number" = 3                       -- Gain
    GROUP BY c."cytoband_name"
    QUALIFY RANK() OVER (ORDER BY COUNT(*) DESC NULLS LAST) <= 11
),
hetdel AS (     -- Top-11 cytobands for Heterozygous Deletions
    SELECT c."cytoband_name"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38                                   c
      ON s."chromosome" = c."chromosome"
     AND s."start_pos"  <= c."hg38_stop"
     AND s."end_pos"    >= c."hg38_start"
    WHERE s."chromosome" = 'chr1'
      AND s."copy_number" = 1                       -- Heterozygous deletion
    GROUP BY c."cytoband_name"
    QUALIFY RANK() OVER (ORDER BY COUNT(*) DESC NULLS LAST) <= 11
)

SELECT DISTINCT a."cytoband_name"
FROM amp   a
JOIN gain  g ON a."cytoband_name" = g."cytoband_name"
JOIN hetdel h ON a."cytoband_name" = h."cytoband_name"
ORDER BY a."cytoband_name";