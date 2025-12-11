/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { STIMULUS_SPLIT } from '../../../modules/local/stimulus/split'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SPLIT_DATA_WF {

    take:
    ch_data
    ch_config_split

    main:

    ch_versions = Channel.empty()

    // ==============================================================================
    // Split data using stimulus
    // ==============================================================================

    // combine each data with each split config
    ch_input = ch_data
        .combine(ch_config_split)
        .multiMap { meta_data, data, meta_config, config ->
            def meta = meta_data + [split_id: meta_config.split_id]
            data:
            [meta, data]
            config:
            [meta, config]
        }

    // run stimulus split
    STIMULUS_SPLIT(
        ch_input.data,
        ch_input.config
    )
    ch_split_data = STIMULUS_SPLIT.out.data_with_split
    ch_versions = ch_versions.mix(STIMULUS_SPLIT.out.versions)

    emit:
    split_data = ch_split_data
    versions = ch_versions // channel: [ versions.yml ]
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
