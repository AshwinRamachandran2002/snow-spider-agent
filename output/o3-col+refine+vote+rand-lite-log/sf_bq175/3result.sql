WITH segment_to_cytoband AS (   -- map KIRC allelic segments to chromosome-1 cytobands
    SELECT
        c."cytoband_name",
        CASE
            WHEN s."copy_number" > 3 THEN 'Amplification'
            WHEN s."copy_number" = 3 THEN 'Gain'
            WHEN s."copy_number" = 1 THEN 'HeterozygousDeletion'
            ELSE NULL
        END                                                     AS "cnv_class"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"  s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38"                                    c
          ON s."chromosome"  = c."chromosome"
         AND s."start_pos"  <= c."hg38_stop"
         AND s."end_pos"    >= c."hg38_start"
    WHERE s."chromosome" = 'chr1'
),
ranked AS (                     -- rank cytobands within each CNV class by event count
    SELECT
        "cytoband_name",
        "cnv_class",
        COUNT(*)                                              AS "event_count",
        RANK()  OVER (PARTITION BY "cnv_class"
                      ORDER BY COUNT(*) DESC NULLS LAST)      AS "class_rank"
    FROM segment_to_cytoband
    WHERE "cnv_class" IS NOT NULL
    GROUP BY "cytoband_name", "cnv_class"
),
cytobands_top11_across_all AS (  -- keep cytobands that sit in the top-11 of every class
    SELECT "cytoband_name"
    FROM   ranked
    WHERE  "class_rank" <= 11
    GROUP  BY "cytoband_name"
    HAVING COUNT(*) = 3          -- must appear in Amplification, Gain and Het-Del
)
SELECT
    r."cytoband_name",
    LISTAGG(r."cnv_class", ', ') WITHIN GROUP (ORDER BY r."cnv_class") AS "classes_in_top11",
    MAX(CASE WHEN r."cnv_class" = 'Amplification'        THEN r."class_rank" END) AS "amplification_rank",
    MAX(CASE WHEN r."cnv_class" = 'Gain'                 THEN r."class_rank" END) AS "gain_rank",
    MAX(CASE WHEN r."cnv_class" = 'HeterozygousDeletion' THEN r."class_rank" END) AS "heterozygous_deletion_rank"
FROM   ranked r
JOIN   cytobands_top11_across_all c
       ON r."cytoband_name" = c."cytoband_name"
GROUP BY r."cytoband_name"
ORDER BY r."cytoband_name";