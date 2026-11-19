package com.example.pokemonchafa

// La actividad y el servicio HCE ejecutan estas operaciones en el hilo principal.
internal val protocoloNfc = ProtocoloNfc()

internal class ProtocoloNfc {
    private class Oferta(val mensaje: ByteArray, val confirmar: () -> Unit)

    private var oferta: Oferta? = null
    private var seleccion: Oferta? = null

    fun ofrecer(mensaje: ByteArray, confirmar: () -> Unit) {
        cancelar()
        oferta = Oferta(mensaje.copyOf(), confirmar)
    }

    fun cancelar() {
        oferta = null
        desconectar()
    }

    fun desconectar() {
        seleccion = null
    }

    fun responder(comando: ByteArray): ByteArray = when {
        comando.contentEquals(seleccionar) || comando.contentEquals(seleccionarConLe) -> {
            val vigente = oferta
            seleccion = vigente
            if (vigente == null) byteArrayOf(0x69, 0x85.toByte()) else vigente.mensaje + exito
        }
        comando.contentEquals(confirmar) -> {
            val vigente = oferta
            if (vigente == null || seleccion !== vigente) {
                byteArrayOf(0x69, 0x85.toByte())
            } else {
                cancelar()
                vigente.confirmar()
                exito.copyOf()
            }
        }
        else -> byteArrayOf(0x6D, 0x00)
    }

    private companion object {
        val seleccionar = byteArrayOf(
            0x00, 0xA4.toByte(), 0x04, 0x00, 0x06,
            0xF0.toByte(), 0x50, 0x4B, 0x43, 0x48, 0x01,
        )
        val seleccionarConLe = seleccionar + 0x00.toByte()
        val confirmar = byteArrayOf(0x80.toByte(), 0x20, 0x00, 0x00, 0x00)
        val exito = byteArrayOf(0x90.toByte(), 0x00)
    }
}
