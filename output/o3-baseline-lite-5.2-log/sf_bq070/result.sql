SELECT
    ROW_NUMBER() OVER (ORDER BY "SOPInstanceUID")                AS "digital_slide_id",   -- numeric id for each digital slide
    "StudyInstanceUID"                                           AS "case_id",
    "SeriesInstanceUID"                                          AS "physical_slide_id",
    "PatientID"                                                  AS "patient_id",
    "collection_id"                                              AS "collection_id",
    "SOPInstanceUID"                                             AS "instance_id",
    "gcs_url"                                                    AS "gcs_url",
    "Columns"                                                    AS "width",
    "Rows"                                                       AS "height",
    ("PixelSpacing")[0]::FLOAT                                   AS "pixel_spacing_mm_per_px",
    CASE                                                        -- map transfer‑syntax to compression label
        WHEN "TransferSyntaxUID" LIKE '1.2.840.10008.1.2.4.9%'  THEN 'jpeg2000'
        WHEN "TransferSyntaxUID" LIKE '1.2.840.10008.1.2.4.5%' 
          OR "TransferSyntaxUID" IN ('1.2.840.10008.1.2.4.50',
                                     '1.2.840.10008.1.2.4.51',
                                     '1.2.840.10008.1.2.4.57',
                                     '1.2.840.10008.1.2.4.70')   THEN 'jpeg'
        ELSE                                                     'other'
    END                                                         AS "compression_type",
    CASE                                                        -- tissue type from SNOMED codes
        WHEN "SpecimenDescriptionSequence"::STRING ILIKE '%"CodeValue":"17621005"%' THEN 'normal'
        WHEN "SpecimenDescriptionSequence"::STRING ILIKE '%"CodeValue":"86049000"%' THEN 'tumor'
    END                                                         AS "tissue_type",
    CASE
        WHEN LOWER("collection_id") = 'tcga_luad'               THEN 'luad'
        WHEN LOWER("collection_id") = 'tcga_lusc'               THEN 'lscc'
    END                                                         AS "cancer_subtype"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
      LOWER("collection_id") IN ('tcga_luad','tcga_lusc')           -- LUAD & LUSC only
  AND "Modality" = 'SM'                                             -- slide microscopy images
  AND "VolumetricProperties" = 'VOLUME'                             -- digital (volume) slides
  AND (  "TransferSyntaxUID" LIKE '1.2.840.10008.1.2.4.9%'          -- JPEG‑2000
      OR "TransferSyntaxUID" LIKE '1.2.840.10008.1.2.4.5%'          -- JPEG
      OR "TransferSyntaxUID" IN ('1.2.840.10008.1.2.4.50',
                                 '1.2.840.10008.1.2.4.51',
                                 '1.2.840.10008.1.2.4.57',
                                 '1.2.840.10008.1.2.4.70') )
  AND "SpecimenDescriptionSequence" IS NOT NULL                     -- have specimen info
  AND "SpecimenDescriptionSequence"::STRING ILIKE '%Tissue freezing medium%'  -- embedding
  AND ( "SpecimenDescriptionSequence"::STRING ILIKE '%"CodeValue":"17621005"%'
     OR "SpecimenDescriptionSequence"::STRING ILIKE '%"CodeValue":"86049000"%')
ORDER BY
    "instance_id" ASC;