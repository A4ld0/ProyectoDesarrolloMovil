package com.example.pokemonchafa

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

class ServicioNfcCriaturas : HostApduService() {
    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray =
        protocoloNfc.responder(commandApdu)

    override fun onDeactivated(reason: Int) {
        protocoloNfc.desconectar()
    }
}
