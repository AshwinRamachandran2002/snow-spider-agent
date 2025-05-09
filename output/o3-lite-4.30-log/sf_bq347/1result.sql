SELECT
  modality,
  COUNT(*) AS total_sop_instances
FROM (
        /* SOP instances in the specified MR series */
        SELECT
          "SOPInstanceUID",
          "Modality" AS modality
        FROM IDC.IDC_V17.DICOM_METADATA
        WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'

        UNION ALL

        /* SEG objects referencing that MR series */
        SELECT
          "SOPInstanceUID",
          'SEG' AS modality
        FROM IDC.IDC_V17.SEGMENTATIONS
        WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
     ) combined
GROUP BY modality
ORDER BY total_sop_instances DESC NULLS LAST, modality
LIMIT 1;