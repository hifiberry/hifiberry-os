state.sndrpihifiberry {
        control.99 {
                iface MIXER
                name DSPVolume
                value.0 255
                value.1 255
                comment {
                        access 'read write user'
                        type INTEGER
                        count 2
                        range '0 - 255'
                        tlv '0000000100000008ffffdcc400000023'
                        dbmin -9020
                        dbmax -95
                        dbvalue.0 -95
                        dbvalue.1 -95
                }
        }
}
