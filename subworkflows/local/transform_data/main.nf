/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { STIMULUS_TRANSFORM } from '../../../modules/local/stimulus/transform'
include { STIMULUS_ENCODE } from '../../../modules/local/stimulus/encode'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TRANSFORM_DATA_WF {

    take:
    ch_split_data
    ch_config_transform
    ch_config_encode

    main:

    ch_versions = Channel.empty()


    // TODO add strategy for handling the launch of stimulus noiser as well as NF-core and other modules
    // TODO if the option is parellalization (for the above) then add csv column splitting  noising  merging

    // ==============================================================================
    // Transform data using stimulus
    // ==============================================================================

    // combine data vs configs based on common key: split_id
    ch_input = ch_split_data
        .combine(ch_config_transform, by: [])
        .map { meta_data, data, meta_config, config ->
            def meta = meta_data + [transform_id: meta_config.transform_id]
            [
                data: [meta, data],
                config: [meta, config]
            ]
        }
        .multiMap { item ->
            data: item.data
            config: item.config
        }

    // run stimulus transform
    STIMULUS_TRANSFORM(
        ch_input.data,
        ch_input.config
    )
    ch_transformed_data = STIMULUS_TRANSFORM.out.transformed_data

    ch_encode_input = ch_transformed_data
        .combine(ch_config_encode, by: [])
        .map { meta_data, data, meta_config, config ->
            def meta = meta_data + [encode_id: meta_config.encode_id]
            [
                data: [meta, data],
                config: [meta, config]
            ]
        }
        .multiMap { item ->
            data: item.data
            config: item.config
        }


    // run stimulus encode
    if (!params.skip_encoding) {
        STIMULUS_ENCODE(
            ch_encode_input.data,
            ch_encode_input.config
        )
        ch_encoded_data = STIMULUS_ENCODE.out.encoded
        ch_versions = ch_versions.mix(STIMULUS_ENCODE.out.versions)
    } else {
        ch_encoded_data = ch_transformed_data
    }

    emit:
    transformed_data = ch_encoded_data
    versions = ch_versions // channel: [ versions.yml ]
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
